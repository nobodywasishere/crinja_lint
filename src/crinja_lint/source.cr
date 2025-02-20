module CrinjaLint
  class Source
    getter env : Crinja
    getter path : String
    getter code : String
    getter template : Crinja::Template
    getter issues : Array(Issue) = Array(Issue).new

    def initialize(@env, @path, @code)
      @template = Crinja::Template.new(
        source: @code,
        env: @env,
        name: @path,
        filename: @path,
        run_parser: false,
      )
    end

    @ast : Crinja::AST::NodeList?

    def ast : Crinja::AST::NodeList
      @ast ||= begin
        Crinja::Parser::TemplateParser.new(@env, @code).parse
      end
    end

    def add_issue(location_start, location_end, message, rule : Rule::Base)
      @issues << Issue.new(location_start, location_end, message, rule)
    end

    def valid?
      @issues.empty?
    end
  end
end
