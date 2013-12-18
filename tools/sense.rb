load_library :serial
import 'processing.serial.Serial'

CALIBRATE_TIME = 5000

def setup
  size 600, 600

  @port = Serial.new self, '/dev/tty.usbmodem1421', 9600
  @values = [0] * 16
  @min = [] #[nil] * 16
  @max = [] #[nil] * 16
  @state = :calibrate_not_touched
  @logging = true
  @threshold = 0.5

  puts @state
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
    case @state
    when :calibrate_not_touched
      @values.each_with_index do |v, i|
        @min[i] = v if !@min[i] or v > @min[i]
      end
    when :calibrate_touched
      @values.each_with_index do |v, i|
        @max[i] = v if !@max[i] or v > @max[i]
      end
    end
    if @logging and @values
      if @state == :running
        puts @values.each_with_index.map { |v, i| if @min[i] and @max[i] then map(v.to_f, @min[i], @max[i], 0, 1).round(2) else v end }.inspect
      #  puts @values.each_with_index.map { |v, i| map v.to_f, @min[i], @max[i], 0, 1 }
      else
        puts @values.inspect
      end
    end
  end

  size = width / 4
  if @values.length != 0
    bar_width = width / @values.length
    @values.each_with_index do |v, i|
      #bar_height = if @max[i] == 0 then 0 else v.to_f / @max[i] end
      #@max[i] = 1 if @max[i] == 0
      #color = 255.0 * v.to_f / @max[i]
      #color = 255.0 * v.to_f / 3000
      if @min[i] and @max[i] and v
        #color = constrain(map(v.to_f, @min[i], @max[i], 0, 255), 0, 255)
        #bar_height = height.to_f * v.to_f / 500
        value = map(v.to_f, @min[i], @max[i], 0.0, 1.0)
        if value < @threshold
          color = 0
        else
          color = 255
        end

        push_matrix
        translate i / 4 * size, i % 4 * size
        noStroke
        fill color
        rect 0, 0, size, size
        pop_matrix
      end
    end
  end
end

def key_pressed
  case key
  when ' '
    case @state
    when :calibrate_not_touched
      @state = :calibrate_touched
      @min.each_with_index do |v, i|
        @max[i] = v + 1
      end
    when :calibrate_touched
      @state = :running
    end
    puts @state
  when 'l'
    @logging = !@logging
  when 'm'
    puts 'min: ' + @min.inspect
    puts 'max: ' + @max.inspect
  when '1', '2', '3', '4', '5', '6', '7', '8', '9'
    @threshold = key.to_i / 10.0
    puts 'set threshold to ' + @threshold.inspect
  end
end
