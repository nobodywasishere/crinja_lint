struct Crinja::Parser::StreamPosition
  include Comparable(self)

  property filename : String?

  def initialize
  end

  def initialize(@filename, line_number @line, column_number @column)
  end

  def line_number
    @line
  end

  def column_number
    @column
  end

  def <=>(other)
    self_file = @filename
    other_file = other.filename
    if self_file.is_a?(String) && other_file.is_a?(String) && self_file == other_file
      {@line, @column} <=> {other.line, other.column}
    else
      nil
    end
  end

  def to_s(io)
    io << filename << ":" << @line << ":" << @column
  end

  # # Returns the same location as this location but with the line and/or
  # # column number(s) changed to the given value(s).
  # def with(line_number = @line, column_number = @column) : self
  #   self.class.new(@filename, line_number, column_number)
  # end

  # Returns the same location as this location but with the line and/or
  # column number(s) adjusted by the given amount(s).
  def adjust(line_number = 0, column_number = 0) : self
    self.class.new(@filename, @line + line_number, @column + column_number)
  end

  # # Seeks to a given *offset* relative to `self`.
  # def seek(offset : self) : self
  #   if offset.filename.as?(String).presence && @filename != offset.filename
  #     raise ArgumentError.new <<-MSG
  #       Mismatching filenames:
  #         #{@filename}
  #         #{offset.filename}
  #       MSG
  #   end

  #   if offset.line_number == 1
  #     self.class.new(@filename, @line, @column + offset.column_number - 1)
  #   else
  #     self.class.new(@filename, @line + offset.line_number - 1, offset.column_number)
  #   end
  # end
end
