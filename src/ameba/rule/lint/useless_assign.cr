# module Ameba::Rule
#   class Lint::UselessAssign < Base
#     properties do
#       since_version "0.1.0"
#       description "Disallows useless variable assignments"
#     end

#     getter assigns : Hash(String, Crinja::AST::ASTNode | Crinja::Parser::Token) = Hash(String, Crinja::AST::ASTNode | Crinja::Parser::Token).new

#     MSG = "Useless assignment to `%s`"

#     def test(source)
#       visitor = AST::TagVisitor.new(self, source)

#       source.ast.accept(visitor)

#       @assigns.each do |name, arg|
#         next if name.starts_with?("_")

#         source.add_issue(
#           arg.location_start,
#           arg.location_end,
#           MSG % name,
#           self
#         )
#       end

#       @assigns.clear
#     rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
#       # These are already handled by `Lint/Tag`
#     end

#     def test(source, node : Crinja::AST::ASTNode, tag : Crinja::Tag::Set)
#       variables = tag.validate_arguments(node, source.env)

#       variables.each do |variable, _|
#         @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
#       end
#     rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
#       # These are already handled by `Lint/Tag`
#     end

#     def test(source, node : Crinja::AST::ASTNode, tag : Crinja::Tag::For)
#       variables, _, _, _ = tag.validate_arguments(node, source.env)

#       variables.each do |variable|
#         @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
#       end
#     rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
#       # These are already handled by `Lint/Tag`
#     end

#     def test(source, node : Crinja::AST::ASTNode, tag : Crinja::Tag::With)
#       variables = tag.validate_arguments(node, source.env)

#       variables.each do |variable, _|
#         @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
#       end
#     rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
#       # These are already handled by `Lint/Tag`
#     end

#     def test(source, node : Crinja::AST::ASTNode, tag : Crinja::Tag::Call)
#       defaults, _ = tag.validate_arguments(node, source.env)

#       defaults.each do |variable, _|
#         @assigns[variable] = node.arguments.find(node) { |i| i.value == variable }
#       end
#     rescue Crinja::TemplateSyntaxError | Crinja::SecurityError | Crinja::FeatureLibrary::UnknownFeatureError
#       # These are already handled by `Lint/Tag`
#     end

#     def test(source, node : Crinja::AST::ASTNode, tag : Crinja::Tag::Import | Crinja::Tag::Extends)
#       # Any assigns that have occurred so far could be used by the imported template.
#       @assigns.clear
#     end

#     def test(source, node : Crinja::AST::IdentifierLiteral)
#       @assigns.delete(node.name)
#     end
#   end
# end
