module Ameba::Presenter
  class RulePresenter < BasePresenter
    def run(rule) : Nil
      output_title "Rule info"

      info = <<-INFO
        Name:           %s
        Severity:       %s
        Enabled:        %s
        Since version:  %s
        INFO

      output_paragraph info % {
        rule.name.colorize(:magenta),
        rule.severity.to_s.colorize(rule.severity.color),
        rule.enabled? ? ENABLED_MARK : DISABLED_MARK,
        (rule.since_version.try(&.to_s) || "N/A").colorize(:white),
      }

      if rule_description = colorize_code_fences(rule.description)
        output_title "Description"
        output_paragraph rule_description
      end
    end

    private def output_title(title)
      output.print "### %s\n\n" % title.upcase.colorize(:yellow)
    end

    private def output_paragraph(paragraph : String)
      output_paragraph(paragraph.lines)
    end

    private def output_paragraph(paragraph : Array)
      paragraph.each do |line|
        output.puts "    #{line}"
      end
      output.puts
    end

    private def colorize_code_fences(string)
      return unless string
      string
        .gsub(/```(.+?)```/m, &.colorize(:dark_gray))
        .gsub(/`(?!`)(.+?)`/, &.colorize(:dark_gray))
    end
  end
end
