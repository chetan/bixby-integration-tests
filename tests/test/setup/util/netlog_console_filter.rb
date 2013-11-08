
class NetLogConsoleFilter

  def initialize(real_out, filter=true)
    @real_out = real_out
    @filter = filter
    @buffer = StringIO.new
  end

  def write(data)

    if !@filter then
      @real_out.write(data)
      return
    end

    # get previous buffer (partial line)
    b = @buffer.read
    @buffer.rewind
    if not b.empty? then
      data = b + data
    end

    # read lines from data
    buff = StringIO.new(data)
    lines = buff.readlines
    if lines then
      if lines.last !~ /\n$/ then
        # store partial lines for next write
        @buffer.write(lines.pop)
      end
      lines.each{ |line|
        if line =~ /^\[netlog\]/ then
          @real_out.puts(line)
        end
      }
    end

  end
end

