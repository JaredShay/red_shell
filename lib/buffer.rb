require_relative "./pixel"

class Buffer
  def initialize(rows: rows, cols: cols, pixel_class: Pixel)
    @rows = rows
    @cols = cols
    @pixel_size = pixel_class.size

    @empty_buffer = initialize_buffer_string

    @buffer_string = @empty_buffer.dup
  end

  def update_at(pixel:, x:, y:)
    index = (y * (@rows) + x) * @pixel_size + y

    @buffer_string[index, @pixel_size] = pixel
  end

  def flush
    @buffer_string.replace(@empty_buffer)
  end

  def out
    @buffer_string
  end

  private

  def initialize_buffer_string
    row_length = @cols * @pixel_size
    new_lines = @rows - 1
    length = @rows * row_length + new_lines

    (" " * length).tap do |buffer|
      (1..@rows - 1).to_a.each do |row|
        buffer[row_length * row] = "\n"
      end
    end
  end
end
