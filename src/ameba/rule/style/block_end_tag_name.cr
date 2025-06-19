module Ameba::Rule
  # Verifies block and other tag names match their end tag name
  class Style::BlockEndTagName < Base
    properties do
      since_version "0.1.0"
      description "Verifies block and other tag names match their end tag name"
    end

    TAGS = %w[block endblock]

    MSG_NO_NAME       = "Missing end tag name `%s`"
    MSG_NAME_MISMATCH = "End tag name `%s` does not match opening tag name `%s`"
    MSG_END_TAG_NAME  = "End tag `%s` does not accept arguments"

    @tag_stack : Array(String?) = Array(String?).new

    def test(source)
      visitor = AST::TagVisitor.new(self, source)

      source.ast.accept(visitor)
    end

    def test(source, node, tag : Crinja::Tag::Block)
      return unless node.name.in?(TAGS)

      if (name = node.arguments.first?) && name.kind.identifier?
        @tag_stack.push(name.value)
      else
        @tag_stack.push(nil)
      end
    end

    def test(source, node : Crinja::AST::EndTagNode)
      if node.name.in?(TAGS)
        return unless expected_name = @tag_stack.pop

        if (name = node.arguments.first?) && name.kind.identifier?
          if name.value != expected_name
            source.add_issue(
              self,
              location_start(node),
              location_end(node),
              MSG_NAME_MISMATCH % {name.value, expected_name},
            )
          end
        else
          source.add_issue(
            self,
            location_start(node),
            location_end(node),
            MSG_NO_NAME % expected_name,
          )
        end
      elsif node.arguments.size > 0 && !node.arguments.first.kind.eof?
        source.add_issue(
          self,
          location_start(node),
          location_end(node),
          MSG_END_TAG_NAME % (node.name || "unknown name"),
        )
      end
    end
  end
end
