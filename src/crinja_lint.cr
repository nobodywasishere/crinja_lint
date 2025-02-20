require "crinja"
require "colorize"

module CrinjaLint
  VERSION = "0.1.0"

  DEFAULT_GLOBS = %w[
    **/*.html.j2
    **/*.jinja2
    !lib
  ]

  def self.run
    files = GlobUtils.find_files_by_globs(DEFAULT_GLOBS)
    env = Crinja.new

    syntax_rule = Rule::Lint::Syntax.new
    rules = Rule.rules.map(&.new)

    sources = files.map { |file| Source.new(env, file, File.read(file)) }
    formatter = DotFormatter.new

    formatter.started(sources)
    sources.each do |source|
      syntax_rule.test(source)

      rules.each do |rule|
        rule.test(source)
      end

      formatter.source_finished(source)
    end
    formatter.finished(sources)
  end
end

require "./crinja_lint/glob_utils"
require "./crinja_lint/issue"
require "./crinja_lint/source"
require "./crinja_lint/formatter/*"
require "./crinja_lint/rule/base"
require "./crinja_lint/rule/**"
