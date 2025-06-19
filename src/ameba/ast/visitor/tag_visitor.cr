module Ameba::AST
  class TagVisitor < NodeVisitor
    def visit(node : Crinja::AST::TagNode)
      @rule.test(@source, node)

      begin
        tag = @source.env.tags[node.name]
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
        return true
      end

      visit_tag(node, tag)

      true
    end

    def visit_tag(node, tag : Crinja::Tag)
      @rule.test(@source, node, tag)
    end

    def visit_tag(node, tag : Crinja::Tag::Set)
      @rule.test(@source, node, tag)
      begin
        variables = tag.validate_arguments(node, @source.env)
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
        return
      end

      variables.each_value(&.accept(self))
    end

    def visit_tag(node, tag : Crinja::Tag::For)
      begin
        _, collection_expr, if_expr, _ = tag.validate_arguments(node, @source.env)
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
        return
      end

      collection_expr.accept(self)
      if_expr.try(&.accept(self))

      @rule.test(@source, node, tag)
    end

    def visit_tag(node, tag : Crinja::Tag::If | Crinja::Tag::If::Elif)
      @rule.test(@source, node, tag)

      begin
        expr = tag.validate_arguments(node, @source.env)
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
        return
      end

      expr.accept(self)
    end

    def visit_tag(node, tag : Crinja::Tag::Call)
      @rule.test(@source, node, tag)

      begin
        _, call = tag.validate_arguments(node, @source.env)
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
        return
      end

      call.accept(self)
    end

    def visit_tag(node, tag : Crinja::Tag::Import)
      @rule.test(@source, node, tag)

      begin
        name_expr, _ = tag.validate_arguments(node, @source.env)
      rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
        # These are already handled by `Lint/Tag`
        return
      end

      name_expr.accept(self)
    end

    private def parse_expression(expression) : String
      lexer = Crinja::Parser::ExpressionLexer.new(@source.env.config, expression)
      parser = Crinja::Parser::ExpressionParser.new(lexer)
      parser.parse
    end
  end
end
