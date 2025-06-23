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
      add_issue(source, node, ex, ex.message.split("\n").first)
    rescue ex : Crinja::SecurityError
      add_issue(source, node, ex, MSG_SECURITY % node.name)
    rescue ex : Crinja::FeatureLibrary::UnknownFeatureError
      add_issue(source, node, ex, MSG_UNKNOWN % node.name)
    rescue ex
      add_issue(source, node, ex, ex.message.try &.split("\n").first || "Unknown error")
    end

    private def add_issue(source : Source, node, ex, msg : String)
      source.add_issue(
        self,
        location_start(ex) || location_start(node),
        location_end(ex) || location_end(node),
        msg
      )
    end
  end
end
