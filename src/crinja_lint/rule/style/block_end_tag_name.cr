module CrinjaLint::Rule
  # Verifies block and other tag names match their end tag name
  class Style::BlockEndTagName < Base
    def severity
      Severity::Convention
    end

    TAGS = %w[block endblock]

    MSG_NO_NAME       = "Missing end tag name `%s`"
    MSG_NAME_MISMATCH = "End tag name `%s` does not match opening tag name `%s`"
    MSG_END_TAG_NAME  = "End tag `%s` does not accept arguments"

    @tag_stack : Array(String?) = Array(String?).new

    def test(source)
      visitor = AST::TagVisitor.new(self, source)

      source.ast.accept(visitor)
    end

    def test(source, node, tag : Crinja::Tag::Block)
      return unless node.name.in?(TAGS)

      if (name = node.arguments.first?) && name.kind.identifier?
        @tag_stack.push(name.value)
      else
        @tag_stack.push(nil)
      end
    end

    def test(source, node : Crinja::AST::EndTagNode)
      if node.name.in?(TAGS)
        return unless expected_name = @tag_stack.pop

        if (name = node.arguments.first?) && name.kind.identifier?
          if name.value != expected_name
            source.add_issue(
              node.location_start,
              node.location_end,
              MSG_NAME_MISMATCH % {name.value, expected_name},
              self
            )
          end
        else
          source.add_issue(
            node.location_start,
            node.location_end,
            MSG_NO_NAME % expected_name,
            self
          )
        end
      elsif node.arguments.size > 0 && !node.arguments.first.kind.eof?
        source.add_issue(
          node.location_start,
          node.location_end,
          MSG_END_TAG_NAME % (node.name || "unknown name"),
          self
        )
      end
    end
  end
end
