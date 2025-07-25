require "../spec_helper"

module Ameba
  private def runner(files = [__FILE__], formatter = DummyFormatter.new)
    config = Config.load
    config.formatter = formatter
    config.globs = files

    config.update_rule VersionedRule.rule_name, enabled: false
    config.update_rule ErrorRule.rule_name, enabled: false
    config.update_rule AtoAA.rule_name, enabled: false
    config.update_rule AtoB.rule_name, enabled: false
    config.update_rule BtoA.rule_name, enabled: false
    config.update_rule BtoC.rule_name, enabled: false
    config.update_rule CtoA.rule_name, enabled: false
    config.update_rule ClassToModule.rule_name, enabled: false
    config.update_rule ModuleToClass.rule_name, enabled: false

    Runner.new(config)
  end

  describe Runner do
    formatter = DummyFormatter.new
    default_severity = Severity::Convention

    describe "#run" do
      it "returns self" do
        runner.run.should_not be_nil
      end

      it "calls started callback" do
        runner(formatter: formatter).run
        formatter.started_sources.should_not be_nil
      end

      it "calls finished callback" do
        runner(formatter: formatter).run
        formatter.finished_sources.should_not be_nil
      end

      it "calls source_started callback" do
        runner(formatter: formatter).run
        formatter.started_source.should_not be_nil
      end

      it "calls source_finished callback" do
        runner(formatter: formatter).run
        formatter.finished_source.should_not be_nil
      end

      it "checks accordingly to the rule #since_version" do
        rules = [VersionedRule.new] of Rule::Base
        source = Source.new "", "source.cr"

        v1_0_0 = SemanticVersion.parse("1.0.0")
        Runner.new(rules, [source], formatter, default_severity, false, v1_0_0).run.success?.should be_true

        v1_5_0 = SemanticVersion.parse("1.5.0")
        Runner.new(rules, [source], formatter, default_severity, false, v1_5_0).run.success?.should be_false

        v1_10_0 = SemanticVersion.parse("1.10.0")
        Runner.new(rules, [source], formatter, default_severity, false, v1_10_0).run.success?.should be_false
      end

      it "skips rule check if source is excluded" do
        path = "source.cr"
        source = Source.new "", path

        all_rules = ([] of Rule::Base).tap do |rules|
          rule = ErrorRule.new
          rule.excluded = [path]
          rules << rule
        end

        Runner.new(all_rules, [source], formatter, default_severity).run.success?.should be_true
      end

      pending "aborts because of an infinite loop" do
        rules = [AtoAA.new] of Rule::Base
        source = Source.new "class A; end", "source.cr"
        message = "Infinite loop in source.cr caused by Ameba/AtoAA"

        expect_raises(Runner::InfiniteCorrectionLoopError, message) do
          Runner.new(rules, [source], formatter, default_severity, autocorrect: true).run
        end
      end

      context "exception in rule" do
        it "raises an exception raised in fiber while running a rule" do
          rule = RaiseRule.new
          rule.should_raise = true
          rules = [rule] of Rule::Base
          source = Source.new "", "source.cr"

          expect_raises(Exception, "something went wrong") do
            Runner.new(rules, [source], formatter, default_severity).run
          end
        end
      end

      pending "handles rules with incompatible autocorrect" do
        rules = [Rule::Performance::MinMaxAfterMap.new, Rule::Style::VerboseBlock.new]
        source = Source.new "list.map { |i| i.size }.max", "source.cr"

        Runner.new(rules, [source], formatter, default_severity, autocorrect: true).run
        source.code.should eq "list.max_of(&.size)"
      end
    end

    describe "#explain" do
      io = IO::Memory.new

      it "writes nothing if sources are valid" do
        io.clear
        runner = runner(formatter: formatter).run
        runner.explain({file: "source.cr", line: 1, column: 2}, io)
        io.to_s.should be_empty
      end

      pending "writes the explanation if sources are not valid and location found" do
        io.clear
        rules = [ErrorRule.new] of Rule::Base
        source = Source.new "a = 1", "source.cr"

        runner = Runner.new(rules, [source], formatter, default_severity).run
        runner.explain({file: "source.cr", line: 1, column: 1}, io)
        io.to_s.should_not be_empty
      end

      it "writes nothing if sources are not valid and location is not found" do
        io.clear
        rules = [ErrorRule.new] of Rule::Base
        source = Source.new "a = 1", "source.cr"

        runner = Runner.new(rules, [source], formatter, default_severity).run
        runner.explain({file: "source.cr", line: 1, column: 2}, io)
        io.to_s.should be_empty
      end
    end

    describe "#success?" do
      it "returns true if runner has not been run" do
        runner.success?.should be_true
      end

      it "returns true if all sources are valid" do
        runner.run.success?.should be_true
      end

      it "returns false if there are invalid sources" do
        rules = Rule.rules.map &.new.as(Rule::Base)
        source = Source.new "WrongConstant = 5", ""

        Runner.new(rules, [source], formatter, default_severity).run.success?.should be_false
      end

      it "depends on the level of severity" do
        rules = Rule.rules.map &.new.as(Rule::Base)
        source = Source.new "WrongConstant = 5\n", ""

        Runner.new(rules, [source], formatter, :error).run.success?.should be_true
        Runner.new(rules, [source], formatter, :warning).run.success?.should be_true
        Runner.new(rules, [source], formatter, :convention).run.success?.should be_false
      end

      it "returns false if issue is disabled" do
        rules = [NamedRule.new] of Rule::Base
        source = Source.new <<-CRYSTAL, ""
          def foo
            bar = 1 # ameba:disable #{NamedRule.name}
          end
          CRYSTAL
        source.add_issue NamedRule.new, location: {2, 1},
          message: "Useless assignment"

        Runner
          .new(rules, [source], formatter, default_severity)
          .run.success?.should be_true
      end
    end

    describe "#run with rules autocorrecting each other" do
      context "with two conflicting rules" do
        context "if there is an offense in an inspected file" do
          pending "aborts because of an infinite loop" do
            rules = [AtoB.new, BtoA.new]
            source = Source.new "class A; end", "source.cr"
            message = "Infinite loop in source.cr caused by Ameba/AtoB -> Ameba/BtoA"

            expect_raises(Runner::InfiniteCorrectionLoopError, message) do
              Runner.new(rules, [source], formatter, default_severity, autocorrect: true).run
            end
          end
        end

        context "if there are multiple offenses in an inspected file" do
          pending "aborts because of an infinite loop" do
            rules = [AtoB.new, BtoA.new]
            source = Source.new <<-CRYSTAL, "source.cr"
              class A; end
              class A_A; end
              CRYSTAL
            message = "Infinite loop in source.cr caused by Ameba/AtoB -> Ameba/BtoA"

            expect_raises(Runner::InfiniteCorrectionLoopError, message) do
              Runner.new(rules, [source], formatter, default_severity, autocorrect: true).run
            end
          end
        end
      end

      context "with two pairs of conflicting rules" do
        pending "aborts because of an infinite loop" do
          rules = [ClassToModule.new, ModuleToClass.new, AtoB.new, BtoA.new]
          source = Source.new "class A_A; end", "source.cr"
          message = "Infinite loop in source.cr caused by Ameba/ClassToModule, Ameba/AtoB -> Ameba/ModuleToClass, Ameba/BtoA"

          expect_raises(Runner::InfiniteCorrectionLoopError, message) do
            Runner.new(rules, [source], formatter, default_severity, autocorrect: true).run
          end
        end
      end

      context "with three rule cycle" do
        pending "aborts because of an infinite loop" do
          rules = [AtoB.new, BtoC.new, CtoA.new]
          source = Source.new "class A; end", "source.cr"
          message = "Infinite loop in source.cr caused by Ameba/AtoB -> Ameba/BtoC -> Ameba/CtoA"

          expect_raises(Runner::InfiniteCorrectionLoopError, message) do
            Runner.new(rules, [source], formatter, default_severity, autocorrect: true).run
          end
        end
      end
    end
  end
end
