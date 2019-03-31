require_relative "./buffer"

class Display
  CLEAR = `clear`

  def initialize(width:, height:)
    @buffer = Buffer.new(rows: height, cols: width)
  end

  def update_at(pixel:, x:, y:)
    @buffer.update_at(pixel: pixel, x: x, y: y)
  end

  def render(source = $stdout)
    CLEAR

    source.puts @buffer.out
  end
end
