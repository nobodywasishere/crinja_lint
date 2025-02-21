module CrinjaLint::Rule
  # Verifies all tags are formatted correctly
  class Lint::Tag < Base
    def severity
      Severity::Error
    end

    MSG_UNKNOWN  = "`%s` tag not found"
    MSG_SECURITY = "Access to `%s` is disabled"

    def test(source, node : Crinja::AST::TagNode)
      tag = source.env.tags[node.name]

      tag.validate_arguments(node, source.env)
    rescue ex : Crinja::TemplateSyntaxError
      source.add_issue(
        ex.location_start,
        ex.location_end,
        ex.message.split("\n").first,
        self
      )
    rescue Crinja::SecurityError
      source.add_issue(
        node.location_start,
        node.location_end,
        MSG_SECURITY % node.name,
        self
      )
    rescue Crinja::FeatureLibrary::UnknownFeatureError
      source.add_issue(
        node.location_start,
        node.location_end,
        MSG_UNKNOWN % node.name,
        self
      )
    rescue ex
      source.add_issue(
        node.location_start,
        node.location_end,
        ex.message.try &.split("\n").first || "Unknown error",
        self
      )
    end
  end
end
