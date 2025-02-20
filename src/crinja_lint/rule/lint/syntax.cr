module CrinjaLint::Rule
  class Lint::Syntax < Base
    def severity
      Severity::Error
    end

    def test(source)
      source.ast
    rescue ex : Crinja::Error
      source.add_issue(
        ex.location_start,
        ex.location_end,
        ex.message.split("\n").first,
        self
      )
    end
  end
end
