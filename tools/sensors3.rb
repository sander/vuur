load_library :serial
import 'processing.serial.Serial'

def setup
  size 600, 600

  @port = Serial.new self, '/dev/tty.usbmodem1411', 9600
  @values = []
  @max = []
  @n = 4
end

def draw
  background 0

  values = ''
  while @port.available > 0
    values = @port.read_bytes_until 10
  end

  if values != ''
    numbers = String(values).strip.split("\t").map { |v| v.to_i }
    @dt = numbers[0]
    @values = numbers[1..-1]
    @values.each_with_index do |v, i|
      @max[i] = v if @max[i] == nil or @max[i] < v
    end
    puts @values.inspect
  end

  size = width / @n
  if @values.length != 0
    bar_width = width / @values.length
    @values.each_with_index do |v, i|
      #bar_height = if @max[i] == 0 then 0 else v.to_f / @max[i] end
      @max[i] = 1 if @max[i] == 0
      #color = 255.0 * v.to_f / @max[i]
      color = 255.0 * v.to_f / 3000
      #bar_height = height.to_f * v.to_f / 30000

      push_matrix
      translate i / @n * size, i % @n * size
      noStroke
      fill color
      rect 0, 0, size, size
      pop_matrix
    end
  end
end
