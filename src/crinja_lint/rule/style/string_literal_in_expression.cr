module CrinjaLint::Rule
  class Style::StringLiteralInExpression < Base
    MSG = "String literal in expression"

    def test(source, node : Crinja::AST::PrintStatement)
      return unless node.expression.is_a?(Crinja::AST::StringLiteral)

      source.add_issue(
        node.location_start,
        node.location_end,
        MSG,
        self
      )
    end
  end
end
