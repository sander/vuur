load_library :serial
import 'processing.serial.Serial'

full_screen

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
FADE_INTERVAL = 200

#######################################################

def setup
  size WIDTH, HEIGHT
  
  load_palettes

  @lithne = Serial.new self, '/dev/tty.usbmodem1411', 115200 
  @panel = Panel.new self

  if File.exist? CALIBRATION_FILE
    @panel.set_from_file CALIBRATION_FILE
    @state = :running
  else
    @panel.threshold = 0.3
    @state = :calibrate_not_touched
  end
  @logging = false
  @font = create_font 'Karla', 12
  @message = {
    on: 0,
    hue1: 222, sat1: 143, bri1: 255,
    hue2: 0, sat2: 0, bri2: 0,
    phue: 0, psat: 0, pbri: 0,
    alternate: 0, # boolean
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
  @preview = -1
  @sent = 0
  @last_colors = [-1, -1]

  """
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

  @sense_time = 0
  @last_sense_position = 0
  @sense_amount = 0
  @sense_amount_time = 0
  @sense_start_time = 0
  """

  @update_message = false

  background 0
end

def draw
  #update

  if @panel.read_values
    case @state
    when :calibrate_not_touched then @panel.set_minima
    when :calibrate_touched then @panel.set_maxima
    end
    @panel.log_values if @logging and @panel.values
  end

  if @draw
    @panel.draw
    draw_mode
    draw_message
    draw_status
  end
end

#######################################################

def send_to_lithne
  string = @message.values.join("\t") + "\n"
  @sent += 1
  @lithne.write string
end

def receive_from_lithne
  if @lithne.available > 0
    bytes = ''
    bytes = @lithne.read_bytes_until 10 while @lithne.available > 0
    puts '< Lithne: ' + String(bytes) if bytes != ''
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

def update
  @panel.reset_cache
  @update_message = false

  #update_sensed
  #update_touched

  if @state == :running
    #on_touch if touching
    fade_out

    # TODO set width etc.
    ceiling = @message[:ceiling]
    @message[:ceiling] = if @points < 20 then 1 else 0 end
    @update_message = true if ceiling != @message[:ceiling]

    #receive_from_lithne # TODO comment out for actual running; this slows things down
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

def touching
  @touch_amount > 0
  #millis - @touch_time < TOUCH_TIMEOUT
end

def distance a, b
  pa = [a % 4, a / 4]
  pb = [b % 4, b / 4]
  Math.sqrt((pa[0] - pb[0])**2 + (pa[1] - pb[1])**2).round 2
end

#######################################################

def on_touch_end
  # TODO select colour and set @update_message
  colors_set = 0
  color = @palettes[:detail_cold][@last_touch_position]
  @message[:hue1] = hue(color).round
  @message[:sat1] = saturation(color).round
  @message[:bri1] = brightness(color).round

  default_width = 50
  @message[:width] = default_width + (@sense_amount / 16.0 * (255.0 - default_width)).to_i

  @update_message = true

  '''
  touch_points.each do |id|
    if colors_set < 2
      unless @last_colors[1] == id
        # TODO
      end
    end
  end
  '''
  @update_message = true
end

def on_touch
  add_points 1 if millis - @points_changed > ADD_POINT_INTERVAL and @points < 100
  point = touch_points[0]
  unless point.nil? or point == @preview
    color = @palettes[:detail_cold][point]
    @message[:phue] = hue(color).round
    @message[:psat] = saturation(color).round
    @message[:pbri] = brightness(color).round
    @update_message = true
  end
end

def fade_out
  puts 'fadeout'
  puts @points_changed
  puts FADE_INTERVAL
  puts @points
  add_points -1 if millis - @points_changed > FADE_INTERVAL and @points > 0
end

def add_points pts
  @points += pts
  @points_changed = millis
  @message[:bri1] = (255.0 * @points / 100).to_i
  @message[:breathe] = 100 - @points
  @update_message = true
end

#######################################################

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
  swiping = false
  "#{@state} | #{unless @receiving then 'not ' end}receiving values | threshold: #{@threshold} | #{@points} points | #{@touch_amount} touches#{if swiping then ' (swiping)' end} | last touch duration: #{@last_touch_duration} | distance: #{@touch_distance} | messages sent: #{@sent}"
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
        @pads[point].neighbors.each do |neighbor|
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
  when 'r'
    @points = 0
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

#######################################################

class Pad
  attr_accessor :neighbors
  attr_accessor :min, :max
  attr_accessor :active, :last_activity
  # TODO store integer that is increased with every interaction session?
  # 

  def initialize panel
    @panel = panel
  end
  
  def id
    @panel.pads.index self
  end

  def neighbors
    @panel.neighbors[id]
  end

  def draw size
    if @active
      no_stroke
      fill 124
      rect 0, 0, size, size
    end
  end
end

class Panel
  attr_accessor :pads
  attr_accessor :threshold
  attr_accessor :receiving
  attr_reader :neighbors

  def initialize sketch
    @arduino = Serial.new sketch, '/dev/tty.usbmodem1421', 115200
    @values = []

    @receiving = false

    @neighbors = {
      0 => [1, 4],        1 => [0, 2, 5],     2 => [1, 3, 6],     3 => [2, 7],
      4 => [0, 5, 8],     5 => [1, 4],        6 => [2, 7],        7 => [3, 6, 11],
      8 => [4, 9, 12],    9 => [8, 13],       10 => [11, 14],     11 => [7, 10, 15],
      12 => [8, 13],      13 => [9, 12, 14],  14 => [10, 13, 15], 15 => [11, 14]
    }
    @pads = (0...16).map { |i| Pad.new self }

    reset_cache
  end

  def set_from_file name
    data = Marshal.load File.read name
    data[:min].each_with_index { |min, i| @pads[i].min = min }
    data[:max].each_with_index { |max, i| @pads[i].max = max }
    @threshold = data[:threshold]
  end

  def set_minima
    @values.each_with_index do |v, i|
      @pads[i].min = v if !@pads[i].min or v > @pads[i].min
    end
  end

  def set_maxima
    @values.each_with_index do |v, i|
      @pads[i].max = v if !@pads[i].max or v > @pads[i].max
    end
  end

  def reset_cache
    @cached_sensed_points = nil
    @cached_touch_points = nil
  end

  def draw
    no_stroke
    fill 0
    rect SENSOR_DISPLAY[0], SENSOR_DISPLAY[1], SENSOR_DISPLAY[2], SENSOR_DISPLAY[3]
    size = SENSOR_DISPLAY[3] / 4
    push_matrix
    translate SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]
    @pads.each_with_index do |pad, i|
      push_matrix
      translate i / 4 * size, i % 4 * size
      pad.draw size
      pop_matrix
    end
    pop_matrix
  end

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
end

class Sequence
  # when no interaction sequence is happening, create a new one on the first
  #
  # want to recognise repeated taps on the same pad (possibly disturbed by other pads)
  # want to recognise a combination of activated pads and activate the effect after one second or when the last activation was lost
  # want to activate a change after one second
  # want to preview colors based on currently touched pads
end

class Log
end
