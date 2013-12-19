load_library :serial
import 'processing.serial.Serial'

#full_screen

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
WIDTH = 1440
HEIGHT = 900
SENSOR_DISPLAY = [10, 10, 580, 580]
MESSAGE_DISPLAY = [10, 600, 1420, 200]
CALIBRATION_FILE = 'calibration.dump'

TOUCH_TIMEOUT = 100
SWIPE_TIMEOUT = 500
TOUCH_COOLDOWN = 100
ADD_POINT_INTERVAL = 100
ADD_POINT_QUICKLY_INTERVAL = 50
FADE_INTERVAL = 1000

#######################################################

def setup
  size WIDTH, HEIGHT
  
  load_palettes

  @port = Serial.new self, '/dev/tty.usbmodem1421', 9600
  @values = []

  name = CALIBRATION_FILE
  if File.exist? name
    data = Marshal.load File.read name
    @min = data[:min]
    @max = data[:max]
    @threshold = data[:threshold]
    @state = :running
  else
    @min = []
    @max = []
    @threshold = 0.3
    @state = :calibrate_not_touched
  end
  @logging = false
  @font = create_font 'Karla', 12
  @receiving = false
  @message = {
    on: 0,
    hue1: 0,
    sat1: 0,
    bri1: 0,
    hue2: 0,
    sat2: 0,
    bri2: 0,
    alternate: 0,
    animate: 0,
    center: 200,
    vary: 0,
    width: 100,
    breathe: 0,
    blink: 0,
    ceiling: 1
  }
  @points = 0
  @mode = :alone
  @draw = true

  reset_cache

  @touch_time = 0
  @touch_start_time = 0
  @touch_end_time = 0
  @touch_amount = 0
  @touch_amount_time = 0
  @touch_distance = 0
  @last_touch_position = -1
  @last_touch_duration = 0
  @swipe_time = 0
  @points_changed = 0

  @update_message = false

  background 0
end

def draw
  update

  if read_values
    case @state
    when :calibrate_not_touched then set_minima
    when :calibrate_touched then set_maxima
    end
    log_values if @logging and @values
  end

  if @draw
    draw_sensed
    draw_touched
    draw_mode
    draw_message
    draw_status
  end
end

#######################################################

def load_palettes
  @palettes = {}
  names = [:detail_cold]
  names.each do |name|
    img = load_image "/Users/sander/Code/vuur/tools/palette_#{name}.png"
    image img, 0, 0
    load_pixels
    colors = []
    (0...16).each do |i|
      colors << pixels[width * (i / 4) + (i % 4)]
    end
    @palettes[name] = colors
  end
  puts @palettes.inspect
end

#######################################################

def reset_cache
  @cached_sensed_points = nil
  @cached_touch_points = nil
end

def update
  reset_cache
  @update_message = false

  tp = touch_points
  if tp.length == 1 and tp[0] != @last_touch_position and millis - @touch_time < SWIPE_TIMEOUT
    # Swiping
    @swipe_time = millis
  end
  if tp.length > 0
    # Currently certainly touching
    @touch_time = millis
    @last_touch_position = tp.last
    if @touch_amount == 0
      @touch_start_time = millis
    end
  end
  if tp.length >= @touch_amount
    # Increasing the touch amount
    @touch_amount = tp.length
    @touch_amount_time = millis
  elsif @touch_amount > 0 and millis - @touch_amount_time > TOUCH_TIMEOUT
    # Decreasing the touch amount
    @touch_amount -= 1
    if @touch_amount == 0
      if millis - @touch_end_time > TOUCH_COOLDOWN
        @touch_end_time = millis
        @last_touch_duration = millis - @touch_start_time
        on_touch_end
      end
    end
  end
  if tp.length > 1
    @touch_distance = 0
    tp.each_with_index do |point, index|
      j = index + 1
      while j < tp.length
        d = distance point, tp[j]
        @touch_distance = d if d > @touch_distance
        j += 1
      end
    end
  end

  on_touch if touching
  fade_out
end

def touching
  @touch_amount > 0
  #millis - @touch_time < TOUCH_TIMEOUT
end

def swiping
  millis - @swipe_time < SWIPE_TIMEOUT
end

def distance a, b
  pa = [a % 4, a / 4]
  pb = [b % 4, b / 4]
  Math.sqrt((pa[0] - pb[0])**2 + (pa[1] - pb[1])**2).round 2
end

#######################################################

def on_touch_end
  # TODO select colour and set @update_message
end

def on_touch
  add_points 1 if millis - @points_changed > ADD_POINT_INTERVAL and @points < 100
end

def fade_out
  add_points -1 if millis - @points_changed > FADE_INTERVAL and @points > 0
end

def add_points pts
  @points += pts
  @points_changed = millis
  @update_message = true
end

#######################################################

def read_values
  values = ''
  values = @port.read_bytes_until 10 while @port.available > 0
  if values != ''
    numbers = String(values).strip.split("\t").map { |v| v.to_i }
    @dt = numbers[0]
    @receiving = true
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

#######################################################

def draw_sensed
  no_stroke
  fill 0
  rect SENSOR_DISPLAY[0], SENSOR_DISPLAY[1], SENSOR_DISPLAY[2], SENSOR_DISPLAY[3]
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
  if @last_touch_position > -1
    i = @last_touch_position
    ellipse_mode CENTER
    stroke 255
    no_fill
    ellipse (i / 4 + 0.5) * size, (i % 4 + 0.5) * size, 20, 20
  end
  pop_matrix
end

def status
  "#{@state} | #{unless @receiving then 'not ' end}receiving values | threshold: #{@threshold} | #{@points} points | #{@touch_amount} touches#{if swiping then ' (swiping)' end} | last touch duration: #{@last_touch_duration} | distance: #{@touch_distance}"
end

def draw_status
  st = status
  unless st == @cached_status
    fill 0
    no_stroke
    rect 0, height - 22, width, 22
    fill 255
    text_size 12
    text_align RIGHT, BOTTOM
    text_font @font
    text st, width - 10, height - 10
    @cached_status = st
  end
end

def draw_mode
  unless @mode == @cached_mode
    fill 0
    no_stroke
    rect SENSOR_DISPLAY[0] + SENSOR_DISPLAY[2], SENSOR_DISPLAY[1], width, SENSOR_DISPLAY[3]
    text_size 12
    text_align CENTER, CENTER
    text_font @font
    fill 255
    text "#{@mode}", (width + SENSOR_DISPLAY[0] + SENSOR_DISPLAY[2]) / 2, SENSOR_DISPLAY[1] + SENSOR_DISPLAY[3] * 0.5
    @cached_mode = @mode
  end
end

def draw_message
  push_matrix
  translate MESSAGE_DISPLAY[0], MESSAGE_DISPLAY[1]

  # background
  no_stroke
  fill 40
  rect 0, 0, MESSAGE_DISPLAY[2], MESSAGE_DISPLAY[3]

  width = (MESSAGE_DISPLAY[2] - 20) / @message.length

  color_mode HSB, 255
  no_stroke
  fill @message[:hue1], @message[:sat1], @message[:bri1]
  rect 15 + width, 10, 3 * width - 10, MESSAGE_DISPLAY[3] - 20
  fill @message[:hue2], @message[:sat2], @message[:bri2]
  rect 15 + 4 * width, 10, 3 * width - 10, MESSAGE_DISPLAY[3] - 20

  @message.each_with_index do |item, i|
    unless [:hue1, :sat1, :bri1, :hue2, :sat2, :bri2].include? item[0]
      text_size 12
      text_align CENTER, CENTER
      text_font @font
      fill 255
      text "#{item[0]}\n#{item[1]}", 10 + (i + 0.5) * width, MESSAGE_DISPLAY[3] / 2
    end
  end
  
  pop_matrix
end

#######################################################

def sensed_points
  if @cached_sensed_points
    @cached_sensed_points
  else
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
    @cached_sensed_points = points
    points
  end
end

def touch_points
  if @cached_touch_points
    @cached_touch_points
  else
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
    points = points.slice 0, 3 if points.length > 3
    @cached_touch_points = points
    points
  end
end

#######################################################

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
      data = { min: @min, max: @max, threshold: @threshold }
      File.open(CALIBRATION_FILE, 'w') { |f| f.write Marshal.dump data }
    when :running
      @min = []
      @max = []
      @state = :calibrate_not_touched
    end
  when 'o'
    @message[:on] = 1 - @message[:on]
  when 'l'
    @logging = !@logging
  when 'm'
    puts 'min: ' + @min.inspect
    puts 'max: ' + @max.inspect
  when '1', '2', '3', '4', '5', '6', '7', '8', '9'
    @threshold = key.to_i / 10.0
  when "\n"
    case @mode
    when :alone then @mode = :group_early
    when :group_early then @mode = :group_noisy
    when :group_noisy then @mode = :group_quiet
    when :group_quiet then @mode = :alone
    end
  when 'd'
    @draw = !@draw
    @cached_status = nil
    @cached_mode = nil
    background 0
  end
end
