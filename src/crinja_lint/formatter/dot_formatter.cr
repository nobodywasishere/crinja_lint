module CrinjaLint
  class DotFormatter < BaseFormatter
    @mutex = Mutex.new

    def started(sources : Array(Source)) : Nil
      output.puts started_message(sources.size)
      output.puts
    end

    def source_finished(source : Source) : Nil
      symbol = source.valid? ? ".".colorize(:green) : "F".colorize(:red)
      @mutex.synchronize { output << symbol }
    end

    def finished(sources : Array(Source)) : Nil
      output.flush
      output << "\n\n"

      failed_sources = sources.reject &.valid?

      failed_sources.each do |source|
        source.issues.each do |issue|
          # next if issue.disabled?
          location = issue.location_start || issue.location_end || Crinja::Parser::StreamPosition.new

          output.print "#{source.path}:#{location}".colorize(:cyan)
          output.puts
          output.puts("[%s] %s: %s" % {
            issue.rule.severity,
            issue.rule.name,
            issue.message,
          })

          if line = source.code.lines[location.line - 1]?
            output.puts line
            output.puts " " * (location.column - 1) + "^"
          else
            output.puts
            output.puts "^"
          end
        end
      end

      output.puts final_message(sources, failed_sources)
    end

    private def started_message(size)
      if size == 1
        "Inspecting 1 file".colorize(:default)
      else
        "Inspecting #{size} files".colorize(:default)
      end
    end

    private def final_message(sources, failed_sources)
      total = sources.size
      failures = failed_sources.sum(&.issues.size)
      color = failures == 0 ? :green : :red

      "#{total} inspected, #{failures} failures".colorize(color)
    end
  end
end
