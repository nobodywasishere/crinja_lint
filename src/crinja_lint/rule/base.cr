module CrinjaLint
  enum Severity
    Error
    Warning
    Convention
  end

  module Rule
    SPECIAL = {
      Lint::Syntax.rule_name,
    }

    def self.rules
      Base.inherited_rules
    end

    abstract class Base
      def severity
        Severity::Warning
      end

      def test(source)
        visitor = AST::NodeVisitor.new(self, source)

        source.ast.accept(visitor)
      end

      def test(source, node : Crinja::AST::ASTNode)
      end

      def name
        {{ @type }}.rule_name
      end

      def group
        {{ @type }}.group_name
      end

      def special?
        name.in?(SPECIAL)
      end

      protected def self.subclasses
        {{ @type.subclasses }}
      end

      protected def self.abstract?
        {{ @type.abstract? }}
      end

      protected def self.rule_name
        name.gsub("CrinjaLint::Rule::", "").gsub("::", '/')
      end

      protected def self.group_name
        rule_name.split('/')[0...-1].join('/')
      end

      protected def self.inherited_rules
        subclasses.each_with_object([] of Base.class) do |klass, obj|
          klass.abstract? ? obj.concat(klass.inherited_rules) : (obj << klass)
        end
      end
    end
  end
end
