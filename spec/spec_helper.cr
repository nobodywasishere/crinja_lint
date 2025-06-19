require "spec"
require "../src/ameba"
require "../src/ameba/spec/support"

module Ameba
  # Dummy Rule which does nothing.
  class DummyRule < Rule::Base
    properties do
      description "Dummy rule that does nothing"
      dummy true
    end

    def test(source)
    end
  end

  class NamedRule < Rule::Base
    properties do
      description "A rule with a custom name"
    end

    def self.name
      "BreakingRule"
    end
  end

  class VersionedRule < Rule::Base
    properties do
      since_version "1.5.0"
      description "Rule with a custom version"
    end

    def test(source)
      issue_for({1, 1}, "This rule always adds an error")
    end
  end

  # Rule extended description
  class ErrorRule < Rule::Base
    properties do
      description "Always adds an error at 1:1"
    end

    def test(source)
      issue_for({1, 1}, "This rule always adds an error")
    end
  end

  # A rule that always raises an error
  class RaiseRule < Rule::Base
    property? should_raise = false

    properties do
      description "Internal rule that always raises"
    end

    def test(source)
      should_raise? && raise "something went wrong"
    end
  end

  class AtoAA < Rule::Base
    properties do
      description "This rule is only used to test infinite loop detection"
    end

    def test(source, node : Crystal::ClassDef | Crystal::ModuleDef)
      return unless name = node_source(node.name, source.lines)
      return unless name.includes?("A")

      issue_for node.name, message: "A to AA" do |corrector|
        corrector.replace(node.name, name.sub("A", "AA"))
      end
    end
  end

  class AtoB < Rule::Base
    properties do
      description "This rule is only used to test infinite loop detection"
    end

    def test(source, node : Crystal::ClassDef | Crystal::ModuleDef)
      return unless name = node_source(node.name, source.lines)
      return unless name.includes?("A")

      issue_for node.name, message: "A to B" do |corrector|
        corrector.replace(node.name, name.tr("A", "B"))
      end
    end
  end

  class BtoA < Rule::Base
    properties do
      description "This rule is only used to test infinite loop detection"
    end

    def test(source, node : Crystal::ClassDef | Crystal::ModuleDef)
      return unless name = node_source(node.name, source.lines)
      return unless name.includes?("B")

      issue_for node.name, message: "B to A" do |corrector|
        corrector.replace(node.name, name.tr("B", "A"))
      end
    end
  end

  class BtoC < Rule::Base
    properties do
      description "This rule is only used to test infinite loop detection"
    end

    def test(source, node : Crystal::ClassDef | Crystal::ModuleDef)
      return unless name = node_source(node.name, source.lines)
      return unless name.includes?("B")

      issue_for node.name, message: "B to C" do |corrector|
        corrector.replace(node.name, name.tr("B", "C"))
      end
    end
  end

  class CtoA < Rule::Base
    properties do
      description "This rule is only used to test infinite loop detection"
    end

    def test(source, node : Crystal::ClassDef | Crystal::ModuleDef)
      return unless name = node_source(node.name, source.lines)
      return unless name.includes?("C")

      issue_for node.name, message: "C to A" do |corrector|
        corrector.replace(node.name, name.tr("C", "A"))
      end
    end
  end

  class ClassToModule < Ameba::Rule::Base
    properties do
      description "This rule is only used to test infinite loop detection"
    end

    def test(source, node : Crystal::ClassDef)
      return unless location = node.location

      end_location = location.adjust(column_number: {{ "class".size - 1 }})

      issue_for location, end_location, message: "class to module" do |corrector|
        corrector.replace(location, end_location, "module")
      end
    end
  end

  class ModuleToClass < Ameba::Rule::Base
    properties do
      description "This rule is only used to test infinite loop detection"
    end

    def test(source, node : Crystal::ModuleDef)
      return unless location = node.location

      end_location = location.adjust(column_number: {{ "module".size - 1 }})

      issue_for location, end_location, message: "module to class" do |corrector|
        corrector.replace(location, end_location, "class")
      end
    end
  end

  class DummyFormatter < Formatter::BaseFormatter
    property started_sources : Array(Source)?
    property finished_sources : Array(Source)?
    property started_source : Source?
    property finished_source : Source?

    def started(sources)
      @started_sources = sources
    end

    def source_finished(source : Source)
      @started_source = source
    end

    def source_started(source : Source)
      @finished_source = source
    end

    def finished(sources)
      @finished_sources = sources
    end
  end

  class TestNodeVisitor < Crystal::Visitor
    NODES = {
      Crystal::NilLiteral,
      Crystal::Var,
      Crystal::Assign,
      Crystal::OpAssign,
      Crystal::MultiAssign,
      Crystal::Block,
      Crystal::Macro,
      Crystal::Def,
      Crystal::If,
      Crystal::While,
      Crystal::MacroLiteral,
      Crystal::Expressions,
      Crystal::ControlExpression,
      Crystal::Call,
    }

    def initialize(node)
      node.accept self
    end

    def visit(node : Crystal::ASTNode)
      true
    end

    {% for node in NODES %}
      {% getter_name = node.stringify.split("::").last.underscore + "_nodes" %}

      getter {{ getter_name.id }} = [] of {{ node }}

      def visit(node : {{ node }})
        {{ getter_name.id }} << node
        true
      end
    {% end %}
  end
end

def with_presenter(klass, *args, deansify = true, **kwargs, &)
  io = IO::Memory.new

  presenter = klass.new(io)
  presenter.run(*args, **kwargs)

  output = io.to_s
  output = Ameba::Formatter::Util.deansify(output).to_s if deansify

  yield presenter, output
end

def as_node(source, *, wants_doc = false)
  Crystal::Parser.new(source)
    .tap(&.wants_doc = wants_doc)
    .parse
end

def as_nodes(source, *, wants_doc = false)
  Ameba::TestNodeVisitor.new(as_node(source, wants_doc: wants_doc))
end

def trailing_whitespace
  ' '
end
