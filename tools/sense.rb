# Configuration

# Load in full screen?
#full_screen

# Screen size and layout (x, y, width, height)
WIDTH = 1440
HEIGHT = 900
SENSOR_DISPLAY = [10, 10, 580, 580]
MESSAGE_DISPLAY = [10, 600, 1420, 200]

# Time intervals are in milliseconds

# How long to wait before marking a pad as untouched
TOUCH_COOLDOWN = 100

# How long a pad needs to sense a high value before it is considered touched
TOUCH_TIMEOUT = 200

# How long to wait before adding another point
ADD_POINT_INTERVAL = 200

# How long to wait before removing a point
FADE_INTERVAL = 1000

# How many taps are needed before activating the 'alternate' mode
TAP_AMOUNT = 3

# Time interval within which TAP_AMOUNT taps need to be done
TAP_TIMEOUT = 2000

# During a long press, how long to wait before the action is applied
APPLY_TIMEOUT = 3000

#######################################################

# Which pads are next to which pads
NEIGHBORS = {
  0 => [1, 4],        1 => [0, 2, 5],     2 => [1, 3, 6],     3 => [2, 7],
  4 => [0, 5, 8],     5 => [1, 4],        6 => [2, 7],        7 => [3, 6, 11],
  8 => [4, 9, 12],    9 => [8, 13],       10 => [11, 14],     11 => [7, 10, 15],
  12 => [8, 13],      13 => [9, 12, 14],  14 => [10, 13, 15], 15 => [11, 14]
}

# Where to store the sensor calibration
CALIBRATION_FILE = 'calibration.dump'

#######################################################

load_library :serial
import 'processing.serial.Serial'

def setup
  size WIDTH, HEIGHT

  load_palettes

  @arduino = Serial.new self, '/dev/tty.usbmodem1421', 115200
  @lithne = Serial.new self, '/dev/tty.usbmodem1411', 115200

  # Store the last measured sensor values
  @values = []

  # Initialise calibration values
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

  # Use to draw on screen
  @font = create_font 'AvenirNext-DemiBold', 14

  # Set to true once sensor data has come in
  @receiving = false

  # Message, the values of which are sent to Lithne on send_to_lithne
  @message = {
    on: 0,        # Send signals to Breakout 404?
    hue1: 222,    # Main effect color
    sat1: 143,
    bri1: 255,
    hue2: 0,      # Secondary effect color
    sat2: 0,
    bri2: 0,
    phue: 0,      # Preview color
    psat: 0,
    pbri: 0,
    alternate: 0, # Show alternating secondary effect color? 1 or 0
    animate: 0,   # Instead of using the secondary color,
                  # animate and animate with the dimmed main color
    center: 200,  # Center of light effect in room, 0-255 mapped to 0.0-8.0
    vary: 0,      # Ignored
    width: 100,   # Width of light effect, 0-255 mapped to 0.0-8.0
    breathe: 0,   # Preview breathe duration between 0 (0 s) and 100 (2 s)
    blink: 0,     # Ignored
    ceiling: 1    # Enable main ceiling light? 1 or 0
  }

  # Points between 0 (no effect) and 100 (full effect)
  @points = 0

  # Draw on screen? Very inefficient, disable for long-term usage
  @draw = true

  # Which point coordinates is the preview based on
  @preview = -1

  # Amount of messages sent
  @sent = 0
  @last_colors = [-1, -1]

  reset_cache

  @touch_time = 0
  @touch_start_time = 0
  @touch_end_time = 0
  @touch_amount = 0
  @touch_amount_time = 0
  @touch_distance = 0
  @last_touch_position = -1
  @last_touch_duration = 0
  @last_touch_durations = []
  @swipe_time = 0
  @points_changed = 0

  @sense_time = 0
  @last_sense_position = 0
  @sense_amount = 0
  @sense_amount_time = 0
  @sense_start_time = 0
  @last_sense = Hash[(0...16).collect { |k| [k, 0] }]

  @update_message = false

  background 0

  log 'Time: ' + Time.new.inspect
end

def draw
  update

  if read_values
    case @state
    when :calibrate_not_touched then set_minima
    when :calibrate_touched then set_maxima
    end
  end

  if @draw
    draw_palette
    draw_sensed
    draw_activated
    draw_message
    draw_status
  end
end

#######################################################

def send_to_lithne
  string = @message.values.join("\t") + "\n"
  @sent += 1
  @lithne.write string
  log 'message: ' + string
end

def receive_from_lithne
  if @lithne.available > 0
    bytes = ''
    bytes = @lithne.read_bytes_until 10 while @lithne.available > 0
    if bytes != ''
      log String(bytes)
    end
  end
end

def log str
  puts "LOG(#{millis}): #{str}"
end

#######################################################

def load_palettes
  @palettes = {}
  names = [:default]
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
end

#######################################################

def reset_cache
  @cached_sensed_points = nil
  @cached_touch_points = nil
  @cached_activated_points = nil
end

def update
  reset_cache
  @update_message = false

  update_sensed
  update_touched
  update_activated

  if @state == :running
    on_touch if touching
    fade_out

    # TODO set width etc.
    @message[:bri1] = (255.0 / 100.0 * @points).round # TODO
    ceiling = @message[:ceiling]
    @message[:ceiling] = if @points < 20 then 1 else 0 end
    @update_message = true if ceiling != @message[:ceiling]

    receive_from_lithne # TODO comment out for actual running; this slows things down
    send_to_lithne if @update_message
  end
end

def update_sensed
  sp = sensed_points
  if sp.length > 0
    @sense_time = millis
    if @sense_amount == 0
      @sense_start_time = millis
    end
  end
  if sp.length >= @sense_amount
    @sense_amount = sp.length
    @sense_amount_time = millis
  elsif @sense_amount > 0 and millis - @sense_amount_time > 300
    @sense_amount -= 1
    if @sense_amount == 0
    end
  end
end

def update_activated
  ap = activated_points
  if ap.length == 0 and not @previous_activated_points.nil? and @previous_activated_points.length > 0
    on_activated_end
  end

  if @previous_activated_points != ap
    log 'activated: ' + ap.inspect
  end

  if touching and millis - @touch_start_time > APPLY_TIMEOUT
    @message[:hue1] = @message[:phue]
    @message[:sat1] = @message[:psat]
    @message[:bri1] = @message[:pbri]
  end

  @previous_activated_points = ap
end

def update_touched
  tp = touch_points
  '''
  if tp.length == 1 and tp[0] != @last_touch_position and millis - @touch_time < SWIPE_TIMEOUT
    # Swiping
    @swipe_time = millis
  end
  '''
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
        @last_touch_durations = @last_touch_durations.unshift([@last_touch_duration, millis]).slice(0, TAP_AMOUNT)
        on_touch_end if @state == :running
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
end

def touching
  @touch_amount > 0
  #millis - @touch_time < TOUCH_TIMEOUT
end

def swiping
  #millis - @swipe_time < SWIPE_TIMEOUT
  false
end

def distance a, b
  pa = [a % 4, a / 4]
  pb = [b % 4, b / 4]
  Math.sqrt((pa[0] - pb[0])**2 + (pa[1] - pb[1])**2).round 2
end

#######################################################

def on_touch_end
  return
  # TODO select colour and set @update_message
  colors_set = 0
  color = @palettes[:default][@last_touch_position]
  @message[:hue1] = hue(color).round
  @message[:sat1] = saturation(color).round
  @message[:bri1] = brightness(color).round

  @message[:phue] = 0
  @message[:psat] = 0
  @message[:pbri] = 0
  @message[:breathe] = 100 - @points

  default_width = 50
  @message[:width] = default_width + (@sense_amount / 16.0 * (255.0 - default_width)).to_i

  @update_message = true

  @update_message = true
end

def on_activated_end
  @message[:hue1] = @message[:phue]
  @message[:sat1] = @message[:psat]
  @message[:bri1] = @message[:pbri]

  @message[:hue2] = @message[:hue1]
  @message[:sat2] = @message[:sat1]
  @message[:bri2] = (@message[:bri1] / 2.0).to_i

  @message[:phue] = 0
  @message[:psat] = 0
  @message[:pbri] = 0
  @message[:breathe] = if @points == 0 then 0 elsif @points == 100 then 1 else 100 - @points end

  # TODO Is this ok?
  @message[:alternate] = if @last_touch_durations.length == TAP_AMOUNT and millis - @last_touch_durations[-1][1] < TAP_TIMEOUT then 1 else 0 end

  default_width = 30
  max_activated = 3.0
  @message[:width] = default_width + (@previous_activated_points.length / max_activated * (255.0 - default_width)).to_i

  @update_message = true
end

def on_touch
  add_points 1 if millis - @points_changed > ADD_POINT_INTERVAL and @points < 100
  point = @center
  unless point.nil? or point == @preview
    @preview = point
    color = center_color
    @message[:phue] = hue(color).round
    @message[:psat] = saturation(color).round
    @message[:pbri] = brightness(color).round
    @message[:breathe] = 0
    @update_message = true
  end
end

def fade_out
  add_points -1 if millis - @points_changed > FADE_INTERVAL and @points > 0
end

def add_points pts
  @points += pts
  @points_changed = millis
  #@message[:bri1] = (255.0 * @points / 100).to_i
  unless @message[:pbri] > 0
    @message[:breathe] = if @points == 0 then 0 elsif @points == 100 then 1 else 100 - @points end
  end
  #@message[:breathe] = 100 - @points if @message[:breathe] > 0
  @message[:breathe] = 0 if @points == 0
  @update_message = true
end

#######################################################

def read_values
  values = ''
  values = @arduino.read_bytes_until 10 while @arduino.available > 0
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

def draw_palette
  no_stroke
  fill 0
  rect 0, 0, SENSOR_DISPLAY[0] + SENSOR_DISPLAY[2], SENSOR_DISPLAY[1] + SENSOR_DISPLAY[3]
  push_matrix
  translate SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]
  width = 10
  size = SENSOR_DISPLAY[3] / 4
  for i in 0...16 do
    push_matrix
    translate i / 4 * size, i % 4 * size
    stroke @palettes[:default][i]
    stroke_weight width
    rect width / 2, width / 2, size - width, size - width


    fill 255
    text_size 12
    text_align CENTER, CENTER
    text_font @font
    text "#{i}", size / 2, size / 2
    fill 0

    pop_matrix
  end
  pop_matrix
end

def draw_sensed
  size = SENSOR_DISPLAY[3] / 4
  push_matrix
  translate SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]
  sensed_points.each do |i|
    push_matrix
    translate i / 4 * size, i % 4 * size
    no_stroke
    fill @palettes[:default][i]
    rect 0, 0, size, size
    pop_matrix
  end
  pop_matrix
end

def draw_activated
  size = SENSOR_DISPLAY[3] / 4
  push_matrix
  translate SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]
  activated_points.each do |i|
    ellipse_mode CENTER
    stroke 255
    stroke_weight 2
    no_fill
    #no_stroke
    #fill 255
    ellipse (i / 4 + 0.5) * size, (i % 4 + 0.5) * size, 20, 20
  end
  unless @center.nil?
    #i = @last_touch_position
    ellipse_mode CENTER
    fill center_color
    stroke 0
    stroke_weight 5
    ellipse @center[0] * size, @center[1] * size, 20, 20
  end
  pop_matrix
end

def status
  "
#{@state}
#{unless @receiving then 'not ' end}receiving values
threshold: #{@threshold}
<<<#{@points} points>>>
#{@touch_amount} touches#{if swiping then ' (swiping)' end}
last touch duration: #{@last_touch_duration}
distance: #{@touch_distance}
messages sent: #{@sent}
  ".strip
end

def draw_status
  st = status
  unless st == @cached_status
    x = SENSOR_DISPLAY[0] + SENSOR_DISPLAY[2] + 30
    y = 10
    w = width - x
    h = SENSOR_DISPLAY[3]
    fill 0
    no_stroke
    rect x, SENSOR_DISPLAY[1], w, h
    fill 255
    text_size 12
    text_align LEFT, TOP
    text_font @font
    text st, x, y
    @cached_status = st
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
  rect 15 + width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20
  fill @message[:hue2], @message[:sat2], @message[:bri2]
  rect 15 + 3 * width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20
  fill @message[:phue], @message[:psat], @message[:pbri]
  rect 15 + 5 * width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20

  @message.each_with_index do |item, i|
    unless [:hue1, :sat1, :bri1, :hue2, :sat2, :bri2, :phue, :psat, :pbri].include? item[0]
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
          if value >= @threshold
            points << i
            @last_sense[i] = millis
          end
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

def activated_points
  if @cached_activated_points
    @cached_activated_points
  else
    points = []
    sensed = sensed_points
    for i in 0...16
      points << i if millis - @last_sense[i] < TOUCH_TIMEOUT
    end
    f = 1.0 / points.length
    @center = points.reduce [0.0, 0.0] do |result, i|
      pos = position i
      [result[0] + f * pos[0], result[1] + f * pos[1]]
    end
    @previous_center = @center
    @center = nil if @center[0] == 0.0 and @center[1] == 0.0
    @cached_activated_points = points
    points
  end
end

#######################################################

def position i
  [(i / 4) + 0.5, (i % 4) + 0.5]
end

def center_color
  c = [0, 0, 0]
  f = 1.0 / activated_points.length
  for i in activated_points
    pad = @palettes[:default][i]
    c = [
      c[0] + f * hue(pad),
      c[1] + f * saturation(pad),
      c[2] + f * brightness(pad)
    ]
  end
  color *c
end

"""
def previous_center_color
  c = [0, 0, 0]
  f = 1.0 / @previous_activated_points.length
  for i in @previous_activated_points
    pad = @palettes[:default][i]
    c = [
      c[0] + f * hue(pad),
      c[1] + f * saturation(pad),
      c[2] + f * brightness(pad)
    ]
  end
  color *c
end
"""

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
  when 'm'
    puts 'min: ' + @min.inspect
    puts 'max: ' + @max.inspect
  when 'r'
    @points = 0
  when '1', '2', '3', '4', '5', '6', '7', '8', '9'
    @threshold = key.to_i / 10.0
  when 'd'
    @draw = !@draw
    @cached_status = nil
    @cached_mode = nil
    background 0
  end
end

class Interaction
  attr_accessor :start
  attr_reader :pads

  def initialize
    @pads = {}
  end
end
