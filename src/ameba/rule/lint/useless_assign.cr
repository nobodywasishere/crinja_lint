module Ameba::Rule
  class Lint::UselessAssign < Base
    properties do
      since_version "0.1.0"
      description "Disallows useless variable assignments"
    end

    MSG = "Useless assignment to `%s`"

    def test(source)
      visitor = AssignVisitor.new(self, source)

      source.ast.accept(visitor)

      visitor.assigns.each do |name, arg|
        next if name.starts_with?("_")

        source.add_issue(
          self,
          location_start(arg),
          location_end(arg).try(&.adjust(column_number: -1)),
          MSG % name,
        ) do |corrector|
          corrector.insert_before(arg.location_start, "_")
        end
      end
    rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
      # These are already handled by `Lint/Tag`
    end

    class AssignVisitor < AST::TagVisitor
      getter assigns : Hash(String, Crinja::AST::ASTNode | Crinja::Parser::Token) = Hash(String, Crinja::AST::ASTNode | Crinja::Parser::Token).new

      def visit_tag(node, tag : Crinja::Tag::Set)
        variables = tag.validate_arguments(node, @source.env)

        variables.each do |variable, _|
          @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
        end
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
      else
        super
      end

      def visit_tag(node : Crinja::AST::ASTNode, tag : Crinja::Tag::For)
        super

        variables, _, _, _ = tag.validate_arguments(node, @source.env)

        variables.each do |variable|
          @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
        end
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
      end

      def visit_tag(node : Crinja::AST::ASTNode, tag : Crinja::Tag::With)
        variables = tag.validate_arguments(node, @source.env)

        variables.each do |variable, _|
          @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
        end
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
      else
        super
      end

      def visit_tag(node : Crinja::AST::ASTNode, tag : Crinja::Tag::Call)
        defaults, _ = tag.validate_arguments(node, @source.env)

        defaults.each do |variable, _|
          @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
        end
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
      else
        super
      end

      def visit_tag(node : Crinja::AST::ASTNode, tag : Crinja::Tag::Include | Crinja::Tag::Extends)
        # Any assigns that have occurred so far could be used by the included template.
        # TODO: travel into source to find uses
        @assigns.clear

        super
      end

      def visit(node : Crinja::AST::IdentifierLiteral)
        @assigns.delete(node.name)
        super
      end
    end
  end
end
