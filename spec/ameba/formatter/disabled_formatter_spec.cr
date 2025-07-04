require "../../spec_helper"

module Ameba::Formatter
  describe DisabledFormatter do
    output = IO::Memory.new
    subject = DisabledFormatter.new output

    before_each do
      output.clear
    end

    describe "#finished" do
      it "writes a final message" do
        subject.finished [Source.new]
        output.to_s.should contain "Disabled rules using inline directives:"
      end

      it "writes disabled rules if any" do
        Colorize.enabled = false

        path = "source.cr"
        s = Source.new(path: path).tap do |source|
          source.add_issue(ErrorRule.new, {1, 2}, message: "ErrorRule", status: :disabled)
          source.add_issue(NamedRule.new, location: {2, 2}, message: "NamedRule", status: :disabled)
        end
        subject.finished [s]
        log = output.to_s
        log.should contain "#{path}:1 #{ErrorRule.rule_name}"
        log.should contain "#{path}:2 #{NamedRule.rule_name}"
      ensure
        Colorize.enabled = true
      end

      it "does not write not-disabled rules" do
        s = Source.new(path: "source.cr").tap do |source|
          source.add_issue(ErrorRule.new, {1, 2}, "ErrorRule")
          source.add_issue(NamedRule.new, location: {2, 2},
            message: "NamedRule", status: :disabled)
        end
        subject.finished [s]
        output.to_s.should_not contain ErrorRule.rule_name
      end
    end
  end
end
