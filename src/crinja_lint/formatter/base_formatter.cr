module CrinjaLint
  class BaseFormatter
    getter output : IO

    def initialize(@output = STDOUT)
    end

    def started(sources : Array(Source)) : Nil
    end

    def source_started(source : Source) : Nil
    end

    def source_finished(source : Source) : Nil
    end

    def finished(sources : Array(Source)) : Nil
    end
  end
end
