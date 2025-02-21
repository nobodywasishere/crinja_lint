module CrinjaLint::Rule
  class Lint::UselessAssign < Base
    getter assigns : Hash(String, Crinja::AST::ASTNode | Crinja::Parser::Token) = Hash(String, Crinja::AST::ASTNode | Crinja::Parser::Token).new

    MSG = "Useless assignment to `%s`"

    def test(source)
      @visitor = visitor = AST::NodeVisitor.new(self, source)

      source.ast.accept(visitor)

      @assigns.each do |name, arg|
        source.add_issue(
          arg.location_start,
          arg.location_end,
          MSG % name,
          self
        )
      end

      @assigns.clear
    end

    # ameba:disable Metrics/CyclomaticComplexity
    def test(source, node : Crinja::AST::TagNode)
      # These should be moved to a `TagVisitor`
      case tag = source.env.tags[node.name]
      when Crinja::Tag::Set
        variables = tag.validate_arguments(node, source.env)

        variables.each do |variable, _|
          @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
        end

        if visitor = @visitor
          variables.each_value(&.accept(visitor))
        end
      when Crinja::Tag::For
        variables, collection_expr, if_expr, _ = tag.validate_arguments(node, source.env)

        if visitor = @visitor
          collection_expr.accept(visitor)
          if_expr.try(&.accept(visitor))
        end

        variables.each do |variable|
          @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
        end
      when Crinja::Tag::If, Crinja::Tag::If::Elif
        expr = tag.validate_arguments(node, source.env)

        if visitor = @visitor
          expr.accept(visitor)
        end
      when Crinja::Tag::With
        variables = tag.validate_arguments(node, source.env)

        variables.each do |variable, _|
          @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
        end
      when Crinja::Tag::Call
        defaults, call = tag.validate_arguments(node, source.env)

        defaults.each do |variable, _|
          @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
        end

        if visitor = @visitor
          call.accept(visitor)
        end
      when Crinja::Tag::Import
        # Any assigns that have occurred so far could be used by the imported template.
        @assigns.clear

        name_expr, _ = tag.validate_arguments(node, source.env)

        if visitor = @visitor
          name_expr.accept(visitor)
        end
      when Crinja::Tag::Extends
        # Any assigns that have occurred so far could be used by the imported template.
        @assigns.clear
      end
    rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
      # These are already handled by `Lint/Tag`
    end

    def test(source, node : Crinja::AST::IdentifierLiteral)
      @assigns.delete(node.name)
    end
  end
end
