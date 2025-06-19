class Crinja::Tag
  def validate_arguments(tag_node : AST::TagNode, env : Crinja)
    raise "Not implemented"
  end
end

class Crinja::Tag::Autoescape
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : AST::ExpressionNode
    parser = ArgumentsParser.new(tag_node.arguments, env.config)
    parser.parse_expression
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::Block
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : {String, Bool}
    parser = Parser.new(tag_node.arguments, env.config)
    parser.parse_block_tag
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::Call
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : {Hash(String, AST::ExpressionNode?), AST::ExpressionNode}
    parser = Parser.new(tag_node.arguments, env.config)
    parser.parse_call_tag
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::Do
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : AST::ExpressionNode
    parser = ArgumentsParser.new(tag_node.arguments, env.config)
    parser.parse_expression
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::EndTag
end

class Crinja::Tag::Extends
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : AST::ExpressionNode
    parser = ArgumentsParser.new(tag_node.arguments, env.config)
    parser.parse_expression
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::Filter
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : {AST::ValuePlaceholder, AST::ExpressionNode}
    parser = Parser.new(tag_node.arguments, env.config)
    parser.parse_filter_tag
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::For
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : {Array(String), AST::ExpressionNode, AST::ExpressionNode?, Bool}
    parser = Parser.new(tag_node.arguments, env.config)
    parser.parse_for_tag
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::From
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : {AST::ExpressionNode, Bool, Hash(String, String)}
    parser = Parser.new(tag_node.arguments, env.config)
    parser.parse_from_tag
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::If
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : AST::ExpressionNode
    parser = ArgumentsParser.new(tag_node.arguments, env.config)
    parser.parse_expression
  ensure
    parser.try &.close
  end

  class Elif
    def validate_arguments(tag_node : AST::TagNode, env : Crinja) : AST::ExpressionNode
      parser = ArgumentsParser.new(tag_node.arguments, env.config)
      parser.parse_expression
    ensure
      parser.try &.close
    end
  end

  class Else
    def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
      if tag_node.arguments.size > 0 && !tag_node.arguments.first.kind.eof?
        raise TemplateSyntaxError.new(tag_node, "#{tag_node.name} does not take arguments").at(tag_node)
      end
    end
  end
end

class Crinja::Tag::Import
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : {AST::ExpressionNode, String?}
    parser = ArgumentsParser.new(tag_node.arguments, env.config)
    name_expr = parser.parse_expression

    context_var = parser.if_identifier "as" do
      parser.next_token
      parser.current_token.value
    end

    {name_expr, context_var}
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::Include
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : {AST::ExpressionNode, Bool, Bool}
    parser = Parser.new(tag_node.arguments, env.config)
    parser.parse_include_tag
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::Macro
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : {String, Hash(String, AST::ExpressionNode?)}
    parser = Parser.new(tag_node.arguments, env.config)
    parser.parse_macro_node
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::Raw
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    ArgumentsParser.new(tag_node.arguments, env.config).close
  end
end

class Crinja::Tag::Set
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Hash(String, AST::ASTNode)
    parser = ArgumentsParser.new(tag_node.arguments, env.config)

    if tag_node.arguments.size == 2
      name = parser.current_token.value
      parser.next_token
      parser.close

      {
        name => tag_node.block,
      } of String => AST::ASTNode
    else
      hash = Hash(String, AST::ASTNode).new

      parser.parse_keyword_list.each do |identifier, expr|
        hash[identifier.name] = expr
      end

      hash
    end
  ensure
    parser.try &.close
  end
end

class Crinja::Tag::With
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Hash(String, Crinja::AST::ExpressionNode)
    hash = Hash(String, AST::ExpressionNode).new

    parser = Parser.new(tag_node.arguments, env.config)
    parser.parse_with_tag_arguments.each do |variable, expression|
      hash[variable.name] = expression
    end

    hash
  ensure
    parser.try &.close
  end
end
