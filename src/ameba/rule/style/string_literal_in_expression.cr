module Ameba::Rule
  class Style::StringLiteralInExpression < Base
    properties do
      since_version "0.1.0"
      description "Disallows string literals in expressions"
    end

    MSG = "String literal in expression"

    def test(source, node : Crinja::AST::PrintStatement)
      return unless node.expression.is_a?(Crinja::AST::StringLiteral)

      source.add_issue(
        self,
        node.location_start,
        node.location_end,
        MSG,
      )
    end
  end
end
