class Crinja::Tag
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    raise "Not implemented"
  end
end

class Crinja::Tag::Autoescape
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    ArgumentsParser.new(tag_node.arguments, env.config).parse_expression
  end
end

class Crinja::Tag::Block
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    Parser.new(tag_node.arguments, env.config).parse_block_tag
  end
end

class Crinja::Tag::Call
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    Parser.new(tag_node.arguments, env.config).parse_call_tag
  end
end

class Crinja::Tag::Do
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    ArgumentsParser.new(tag_node.arguments, env.config).parse_expression
  end
end

class Crinja::Tag::EndTag
end

class Crinja::Tag::Extends
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    ArgumentsParser.new(tag_node.arguments, env.config).parse_expression
  end
end

class Crinja::Tag::Filter
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    Parser.new(tag_node.arguments, env.config).parse_filter_tag
  end
end

class Crinja::Tag::For
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    Parser.new(tag_node.arguments, env.config).parse_for_tag
  end
end

class Crinja::Tag::From
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    Parser.new(tag_node.arguments, env.config).parse_from_tag
  end
end

class Crinja::Tag::If
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    ArgumentsParser.new(tag_node.arguments, env.config).parse_expression
  end

  class Elif
    def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
      ArgumentsParser.new(tag_node.arguments, env.config).parse_expression
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
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    ArgumentsParser.new(tag_node.arguments, env.config).parse_expression
  end
end

class Crinja::Tag::Include
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    Parser.new(tag_node.arguments, env.config).parse_include_tag
  end
end

class Crinja::Tag::Macro
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    Parser.new(tag_node.arguments, env.config).parse_macro_node
  end
end

class Crinja::Tag::Raw
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    ArgumentsParser.new(tag_node.arguments, env.config).close
  end
end

class Crinja::Tag::Set
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    parser = ArgumentsParser.new(tag_node.arguments, env.config)

    if tag_node.arguments.size == 2
      parser.next_token
      parser.close
    else
      parser.parse_keyword_list
    end
  end
end

class Crinja::Tag::With
  def validate_arguments(tag_node : AST::TagNode, env : Crinja) : Nil
    Parser.new(tag_node.arguments, env.config).parse_with_tag_arguments
  end
end
