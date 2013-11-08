
class NetLogConsoleFilter

  def initialize
    @buffer = StringIO.new
    @netlog = []
    @console = []
  end

  def write(data)

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
          @netlog << line
        else
          @console << line
        end
      }
    end

  end # write

  def netlog
    @netlog.join("")
  end

  def console
    @console.join("")
  end

end

