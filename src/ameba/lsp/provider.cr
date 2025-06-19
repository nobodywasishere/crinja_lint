module Ameba::Lsp
  class Provider < Larimar::Provider
    Log = ::Larimar::Log.for(self)

    include Larimar::CodeActionProvider

    @diagnostics : Hash(URI, Array(LSProtocol::Diagnostic)) = Hash(URI, Array(LSProtocol::Diagnostic)).new
    @issues : Hash(URI, Array(Ameba::Issue)) = Hash(URI, Array(Ameba::Issue)).new

    class DiagnosticsFormatter < Ameba::Formatter::BaseFormatter
      getter diagnostics : Array(LSProtocol::Diagnostic) = Array(LSProtocol::Diagnostic).new
      @mutex : Mutex = Mutex.new
      property cancellation_token : CancellationToken?

      def source_finished(source : Ameba::Source) : Nil
        source.issues.each do |issue|
          next if issue.disabled?

          cancellation_token.try &.cancelled!

          start_location = LSProtocol::Position.new(
            line: (issue.location.try(&.line_number.to_u32) || 1_u32) - 1,
            character: (issue.location.try(&.column_number.to_u32) || 1_u32) - 1,
          )

          end_location = LSProtocol::Position.new(
            line: (issue.end_location.try(&.line_number.to_u32) || issue.location.try(&.line_number.to_u32) || 1_u32) - 1,
            character: (issue.end_location.try(&.column_number.to_u32) || issue.location.try(&.column_number.to_u32) || 1_u32),
          )

          @mutex.synchronize do
            diagnostics << LSProtocol::Diagnostic.new(
              message: "[#{issue.rule.name}] #{issue.message}",
              range: LSProtocol::Range.new(
                start: start_location,
                end: end_location
              ),
              severity: convert_severity(issue.rule.severity)
            )
          end
        end
      end

      def convert_severity(severity : Ameba::Severity) : LSProtocol::DiagnosticSeverity
        case severity
        in .error?
          LSProtocol::DiagnosticSeverity::Error
        in .warning?
          LSProtocol::DiagnosticSeverity::Warning
        in .convention?
          LSProtocol::DiagnosticSeverity::Information
        end
      end
    end

    def on_open(document : Larimar::TextDocument) : Nil
      handle_ameba(document)
    end

    def on_change(document : Larimar::TextDocument) : Nil
      handle_ameba(document)
    end

    def on_save(document : Larimar::TextDocument) : Nil
      handle_ameba(document)
    end

    def on_close(document : Larimar::TextDocument) : Nil
      controller.server.send_msg(
        LSProtocol::PublishDiagnosticsNotification.new(
          params: LSProtocol::PublishDiagnosticsParams.new(
            diagnostics: [] of LSProtocol::Diagnostic,
            uri: document.uri
          )
        )
      )
    end

    private def handle_ameba(document : Larimar::TextDocument) : Nil
      source = Ameba::Source.new(document.to_s, document.uri.path)
      formatter = DiagnosticsFormatter.new

      config_path : String? = nil

      workspace_folder : String? = Larimar::Workspace.find_closest_shard_yml(document.uri).try(&.path)
      if workspace_folder
        test_path : Path? = Path.new(workspace_folder, ".crinja_lint.yml")

        if File.exists?(test_path)
          config_path = test_path.to_s
        end
      end

      Log.debug(&.emit("Running ameba", source: document.uri.path, config: config_path))

      config = Ameba::Config.load(path: config_path)
      config.sources = [source]
      config.formatter = formatter

      # Disabling these as they're common when typing
      config.update_rules(%w[Layout/TrailingBlankLines Layout/TrailingWhitespace], enabled: false)

      begin
        Ameba::Runner.new(config).run
      rescue CancellationException
      end

      @issues[document.uri] = source.issues
      @diagnostics[document.uri] = formatter.diagnostics

      controller.server.send_msg(
        LSProtocol::PublishDiagnosticsNotification.new(
          params: LSProtocol::PublishDiagnosticsParams.new(
            diagnostics: formatter.diagnostics,
            uri: document.uri
          )
        )
      )
    end

    def provide_code_actions(
      document : Larimar::TextDocument,
      range : LSProtocol::Range | LSProtocol::SelectionRange,
      context : LSProtocol::CodeActionContext,
      token : CancellationToken?,
    ) : Array(LSProtocol::CodeAction | LSProtocol::Command)?
      result = [] of LSProtocol::CodeAction | LSProtocol::Command
      diagnostics = @diagnostics[document.uri]?
      issues = @issues[document.uri]?

      if diagnostics.nil? || issues.nil?
        return
      end

      diagnostics.each_with_index do |diagnostic, idx|
        break unless issue = issues[idx]?
        next unless issue.correctable?

        result << LSProtocol::CodeAction.new(
          title: "Fix #{issue.rule.name}",
          diagnostics: [diagnostic],
          kind: LSProtocol::CodeActionKind::QuickFix,
          is_preferred: true,
          data: JSON::Any.new({
            "uri" => JSON::Any.new(document.uri.to_s),
            "idx" => JSON::Any.new(idx),
          } of String => JSON::Any)
        )
      end

      result
    end

    def resolve_code_action(
      code_action : LSProtocol::CodeAction,
      token : CancellationToken?,
    ) : LSProtocol::CodeAction?
      return unless (data = code_action.data.try(&.as_h?)) &&
                    (document_uri_string = data["uri"]?.try(&.as_s?)) &&
                    (document_uri = URI.parse(document_uri_string)) &&
                    (document = controller.@documents[document_uri]?) &&
                    (diagnostic = code_action.diagnostics.try(&.first?)) &&
                    (issue_idx = data["idx"]?.try(&.as_i?)) &&
                    (issue = @issues[document_uri]?.try(&.[issue_idx]))

      result = nil

      document.mutex.synchronize do
        corrector = Ameba::Source::Corrector.new(document.to_s)
        issue.correct(corrector)

        text_edits = [] of LSProtocol::TextEdit
        get_text_edits(document, text_edits, corrector.@rewriter.@action_root)

        workspace_edit = LSProtocol::WorkspaceEdit.new(
          changes: {document.uri => text_edits}
        )

        result = LSProtocol::CodeAction.new(
          title: "Fix #{issue.rule.name}",
          diagnostics: [diagnostic],
          edit: workspace_edit,
          kind: LSProtocol::CodeActionKind::QuickFix,
          is_preferred: true,
        )
      end

      result
    end

    private def get_text_edits(document, edits : Array(LSProtocol::TextEdit), action : Ameba::Source::Rewriter::Action) : Nil
      begin_pos = document.index_to_position(action.begin_pos)
      end_pos = document.index_to_position(action.begin_pos)

      if (insert_before = action.insert_before) && !insert_before.empty?
        edits << LSProtocol::TextEdit.new(
          new_text: insert_before,
          range: LSProtocol::Range.new(
            start: begin_pos,
            end: begin_pos
          )
        )
      end

      if (insert_after = action.insert_after) && !insert_after.empty?
        edits << LSProtocol::TextEdit.new(
          new_text: insert_after,
          range: LSProtocol::Range.new(
            start: end_pos,
            end: end_pos
          )
        )
      end

      if replacement = action.replacement
        edits << LSProtocol::TextEdit.new(
          new_text: replacement,
          range: LSProtocol::Range.new(
            start: document.index_to_position(action.begin_pos),
            end: document.index_to_position(action.end_pos)
          )
        )
      else
        action.@children.each do |child|
          get_text_edits(document, edits, child)
        end
      end
    end
  end
end
