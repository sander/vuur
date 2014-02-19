load_library :serial
import 'processing.serial.Serial'

def setup
  size 400, 300
  
  @lithne = Serial.new self, '/dev/tty.usbmodem1411', 115200 
  @sent = 0

  @message = {
    on: 1,
    #hue1: 222, sat1: 143, bri1: 255,
    #hue1: 222, sat1: 143, bri1: 255,
    #hue1: (48.0/360.0*255.0).round, sat1: 255, bri1: 255,
    hue1: 0, sat1: 0, bri1: 255,
    hue2: (25.0/360.0*255.0).round, sat2: 255, bri2: 255,
    phue: 0, psat: 0, pbri: 255,
    alternate: 1, # boolean
    animate: 0,
    center: 200,
    vary: 0,
    width: 150,
    breathe: 0,
    blink: 0,
    ceiling: 1
  }
end

def draw
  if millis - @sent > 1000
    send_to_lithne
    @sent = millis
  end
end

#######################################################

def send_to_lithne
  string = @message.values.join("\t") + "\n"
  @lithne.write string
end
