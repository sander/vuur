load_library :serial
import 'processing.serial.Serial'

def setup
  size 800, 600

  @port = Serial.new self, '/dev/tty.usbmodem1411', 9600
  @values = []
  @max = []
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

  if @values.length != 0
    bar_width = width / @values.length
    @values.each_with_index do |v, i|
      #bar_height = if @max[i] == 0 then 0 else v.to_f / @max[i] end
      @max[i] = 1 if @max[i] == 0
      #bar_height = height.to_f * v.to_f / @max[i]
      bar_height = height.to_f * v.to_f / 30000

      push_matrix
      translate i * bar_width, 0
      noStroke
      fill 255
      rect 0, height - bar_height, bar_width, bar_height
      pop_matrix
    end
  end
end
