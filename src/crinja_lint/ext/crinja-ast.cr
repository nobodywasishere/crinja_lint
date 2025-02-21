module Crinja::AST
  class ASTNode
    def accept(visitor)
      if visitor.visit(self)
        accept_children(visitor)
      end

      visitor.end_visit(self)
    end

    def accept_children(visitor)
    end
  end

  class Empty
    def accept_children(visitor)
    end
  end

  class BinaryExpression
    def accept_children(visitor)
      @left.accept(visitor)
      @right.accept(visitor)
    end
  end

  class ComparisonExpression
    def accept_children(visitor)
      @left.accept(visitor)
      @right.accept(visitor)
    end
  end

  class UnaryExpression
    def accept_children(visitor)
      @right.accept(visitor)
    end
  end

  class CallExpression
    def accept_children(visitor)
      @identifier.accept(visitor)
      @argumentlist.accept(visitor)
      @keyword_arguments.each do |key, val|
        key.accept(visitor)
        val.accept(visitor)
      end
    end
  end

  class FilterExpression
    def accept_children(visitor)
      @target.accept(visitor)
      @identifier.accept(visitor)
      @argumentlist.accept(visitor)
      @keyword_arguments.each do |key, val|
        key.accept(visitor)
        val.accept(visitor)
      end
    end
  end

  class TestExpression
    def accept_children(visitor)
      @target.accept(visitor)
      @identifier.accept(visitor)
      @argumentlist.accept(visitor)
      @keyword_arguments.each do |key, val|
        key.accept(visitor)
        val.accept(visitor)
      end
    end
  end

  class MemberExpression
    def accept_children(visitor)
      @identifier.accept(visitor)
      @member.accept(visitor)
    end
  end

  class IndexExpression
    def accept_children(visitor)
      @identifier.accept(visitor)
      @argument.accept(visitor)
    end
  end

  class ExpressionList
    def accept_children(visitor)
      @children.each(&.accept(visitor))
    end
  end

  class IdentifierList
    def accept_children(visitor)
      @children.each(&.accept(visitor))
    end
  end

  class NullLiteral
    def accept_chilren(visitor)
    end
  end

  class IdentifierLiteral
    def accept_chilren(visitor)
    end
  end

  class SplashOperator
    def accept_children(visitor)
      @right.accept(visitor)
    end
  end

  class StringLiteral
    def accept_chilren(visitor)
    end
  end

  class FloatLiteral
    def accept_chilren(visitor)
    end
  end

  class IntegerLiteral
    def accept_chilren(visitor)
    end
  end

  class BooleanLiteral
    def accept_chilren(visitor)
    end
  end

  class ArrayLiteral
    def accept_children(visitor)
      @children.each(&.accept(visitor))
    end
  end

  class TupleLiteral
    def accept_children(visitor)
      @children.each(&.accept(visitor))
    end
  end

  class DictLiteral
    def accept_children(visitor)
      @children.each do |key, val|
        key.accept(visitor)
        val.accept(visitor)
      end
    end
  end

  class ValuePlaceholder
    def accept_chilren(visitor)
    end
  end

  class NodeList
    def accept_children(visitor)
      @children.each(&.accept(visitor))
    end
  end

  class PrintStatement
    def accept_children(visitor)
      @expression.accept(visitor)
    end
  end

  class Expressions
    def accept_children(visitor)
      @children.each(&.accept(visitor))
    end
  end

  class TagNode
    def accept_children(visitor)
      @block.accept(visitor)
      @end_tag.try &.accept(visitor)
    end
  end

  class EndTagNode
    def accept_children(visitor)
    end
  end

  class Note
    def accept_children(visitor)
    end
  end

  class FixedString
    def accept_children(visitor)
    end
  end
end
