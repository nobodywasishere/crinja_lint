module Ameba::Rule
  # Verifies all tags are formatted correctly
  class Lint::Tag < Base
    properties do
      since_version "0.1.0"
      description "Verifies all tags are formatted correctly"
    end

    MSG_UNKNOWN  = "`%s` tag not found"
    MSG_SECURITY = "Access to `%s` is disabled"

    def test(source, node : Crinja::AST::TagNode)
      tag = source.env.tags[node.name]

      tag.validate_arguments(node, source.env)
    rescue ex : Crinja::TemplateSyntaxError
      source.add_issue(
        self,
        ex.location_start,
        ex.location_end,
        ex.message.split("\n").first,
      )
    rescue Crinja::SecurityError
      source.add_issue(
        self,
        node.location_start,
        node.location_end,
        MSG_SECURITY % node.name,
      )
    rescue Crinja::FeatureLibrary::UnknownFeatureError
      source.add_issue(
        self,
        node.location_start,
        node.location_end,
        MSG_UNKNOWN % node.name,
      )
    rescue ex
      source.add_issue(
        self,
        node.location_start,
        node.location_end,
        ex.message.try &.split("\n").first || "Unknown error",
      )
    end
  end
end
