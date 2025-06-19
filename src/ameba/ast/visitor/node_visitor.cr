module Ameba::AST
  class NodeVisitor
    include Crinja::AST

    @rule : Rule::Base
    @source : Source

    def initialize(@rule, @source)
    end

    def visit(node : ASTNode)
      @rule.test(@source, node)

      true
    end

    def end_visit(node : ASTNode)
      true
    end
  end
end
