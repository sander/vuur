load_library :serial
import 'processing.serial.Serial'

NEIGHBORS = {
  0 => [1, 4],
  1 => [0, 2, 5],
  2 => [1, 3, 6],
  3 => [2, 7],
  4 => [0, 5, 8],
  5 => [1, 4],
  6 => [2, 7],
  7 => [3, 6, 11],
  8 => [4, 9, 12],
  9 => [8, 13],
  10 => [11, 14],
  11 => [7, 10, 15],
  12 => [8, 13],
  13 => [9, 12, 14],
  14 => [10, 13, 15],
  15 => [11, 14]
}
WIDTH = 800
HEIGHT = 600
SENSOR_DISPLAY = [10, 10, 400, 400]

def setup
  size WIDTH, HEIGHT

  @port = Serial.new self, '/dev/tty.usbmodem1421', 9600
  @values = []
  @min = []
  @max = []
  @state = :calibrate_not_touched
  @logging = false
  @threshold = 0.3
  @font = create_font 'Karla', 12
end

def draw
  background 0

  if read_values
    case @state
    when :calibrate_not_touched then set_minima
    when :calibrate_touched then set_maxima
    end
    log_values if @logging and @values
  end

  draw_sensed
  draw_touched
  draw_state
end

def read_values
  values = ''
  values = @port.read_bytes_until 10 while @port.available > 0
  if values != ''
    numbers = String(values).strip.split("\t").map { |v| v.to_i }
    @dt = numbers[0]
    puts 'first values' if @values == []
    @values = numbers[1..-1]
    true
  else
    false
  end
end

def log_values
  if @state == :running
    puts @values.each_with_index.map { |v, i|
      if @min[i] and @max[i]
        map(v.to_f, @min[i], @max[i], 0, 1).round(2)
      else
        v
      end
    }.inspect
  else
    puts @values.inspect
  end
end

def set_minima
  @values.each_with_index do |v, i|
    @min[i] = v if !@min[i] or v > @min[i]
  end
end

def set_maxima
  @values.each_with_index do |v, i|
    @max[i] = v if !@max[i] or v > @max[i]
  end
end

def draw_sensed
  size = SENSOR_DISPLAY[3] / 4
  push_matrix
  translate SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]
  sensed_points.each do |i|
    push_matrix
    translate i / 4 * size, i % 4 * size
    no_stroke
    fill 124
    rect 0, 0, size, size
    pop_matrix
  end
  pop_matrix
end

def draw_touched
  size = SENSOR_DISPLAY[3] / 4
  push_matrix
  translate SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]
  touch_points.each do |i|
    ellipse_mode CENTER
    no_stroke
    fill 255
    ellipse (i / 4 + 0.5) * size, (i % 4 + 0.5) * size, 20, 20
  end
  pop_matrix
end

def draw_state
  text_size 12
  text_align RIGHT, BOTTOM
  text_font @font
  text @state.to_s, width - 10, height - 10
end

def sensed_points
  points = []
  if @values.length != 0
    @values.each_with_index do |v, i|
      if @min[i] and @max[i] and v
        value = map v.to_f, @min[i], @max[i], 0.0, 1.0
        points << i if value >= @threshold
      else
      end
    end
  end
  points
end

def touch_points
  try = (0...16).to_a
  sensed = sensed_points
  i = 0
  points = []
  while i < try.length
    point = try[i]
    if sensed.include? point
      points << point
      NEIGHBORS[point].each do |neighbor|
        try.delete neighbor if sensed.include? neighbor and neighbor > point
      end
    end
    i = i + 1
  end
  points = [points.first, points.last] if points.length > 2
  points
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
    when :running
      @min = []
      @max = []
      @state = :calibrate_not_touched
    end
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
