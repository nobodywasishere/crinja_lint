module CrinjaLint
  class Issue
    getter rule : Rule::Base
    getter message : String
    getter location_start : Crinja::Parser::StreamPosition?
    getter location_end : Crinja::Parser::StreamPosition?

    def initialize(@location_start, @location_end, @message, @rule)
    end
  end
end
