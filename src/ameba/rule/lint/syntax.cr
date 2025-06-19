module Ameba::Rule
  class Lint::Syntax < Base
    properties do
      since_version "0.1.0"
      description "Reports invalid Crinja syntax"
    end

    def severity
      Severity::Error
    end

    def test(source)
      source.ast
    rescue ex : Crinja::Error
      source.add_issue(
        self,
        location_start(ex),
        location_end(ex),
        ex.message.split("\n").first
      )
    end
  end
end
