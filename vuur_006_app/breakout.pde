final long REGISTER_INTERVAL = 50000;
long lastRegistered = -REGISTER_INTERVAL;
FunctionTable ft = new FunctionTable();

char parameterArray[] = {
  // Local Indirect
  2, // 2 colors
  0, // col 1: yellow
  0, // col 2: red
  255, // sat 1: full
  0, // sat 2: full
  255, // bright 1: full
  0, // bright 2: full
  10, // var
  0, // spd

  // Peripheral Indirect
  2, // 2 colors
  0, // col 1: blue
  0, // col 2: red
  0, // sat 1: full
  0, // sat 2: full
  0, // bright 1: full
  0, // bright 2: full
  15, // var
  0, // spd

  // Local Direct
  1, // 1 colors
  42, // col 1: yellow
  0, // col 2: red
  255, // sat 1: full
  255, // sat 2: full
  255, // bright 1: full
  255, // bright 2: full
  5, // var
  0, // spd

  // Peripheral Direct
  1, // 1 colors
  42, // col 1: yellow
  0, // col 2: red
  255, // sat 1: full
  255, // sat 2: full
  255, // bright 1: full
  255, // bright 2: full
  5, // var
  0, // spd

  255 //  width
};

int loudness;
int motion;

public class FunctionTable implements MessageListener
{
  public void messageEventReceived( MessageEvent event )
  {
    if (event.getMessage().functionIs("motion")) {
      motion = event.getMessage().getArgument(0);
      log("motion", motion);
    } 
    else if (event.getMessage().functionIs("loudness")) {
      loudness = event.getMessage().getArgument(0);
      log("loudness", loudness);
    }
  }
}

void initBreakout() {
  if (USE_HUB)
    lithne = new Lithne(this, "/dev/tty.usbmodem1a12413", 115200);
  else
    lithne = new Lithne(this, "/dev/tty.usbmodem1413", 115200);
  lithne.enableDebug();
  lithne.begin();

  lithne.addMessageListener(ft);

  nm.addNode("00 13 a2 00 40 79 ce 37", "Color Coves");
  nm.addNode("00 13 a2 00 40 79 ce 25", "CCT Ceiling Tiles");
  nm.addNode("00 13 a2 00 40 79 ce 24", "Solime");
}

void sendParamArray()
{
  setLightParameters( parameterArray );
}

void setLightParameters( char paramArray[] )
{
  Message msg  =  new Message();
  msg.toXBeeAddress64( nm.getXBeeAddress64("Color Coves") );
  msg.setFunction( "sizedParameters" );
  msg.setScope( "Breakout404" );

  for (int i = 0; i < paramArray.length; i++)
  {
    msg.addByte(paramArray[i]);
  }

  //println("SENDING NEW MSG: " + msg.toString());
  lithne.send( msg );

  log("parameters", charArrayToString(paramArray));
}

void setUserLocation( int x, int y )
{
  Message msg  =  new Message();
  msg.toXBeeAddress64( nm.getXBeeAddress64("Color Coves") );
  msg.setFunction( "setUserLocation" );
  msg.setScope( "Breakout404" );

  msg.addArgument(x);
  msg.addArgument(y);


  //println("SENDING NEW MSG: " + msg.toString());
  lithne.send( msg );
}

void setCeiling(boolean on) {
  Message msg = new Message();
  msg.setFunction("setCCTParameters");
  msg.setScope("Breakout404");
  msg.toXBeeAddress64( nm.getXBeeAddress64("CCT Ceiling Tiles") );
  for (int i = 0; i < 5; i++) {
    msg.addArgument(i);
    msg.addArgument(1);
    msg.addArgument(!on ? 255 : 100);
    msg.addArgument(!on ? 200 : 0);
  }
  lithne.send(msg);
}

void turnOff() {
  Message msg  =  new Message();
  msg.toXBeeAddress64( nm.getXBeeAddress64("Color Coves") );
  msg.setFunction( "setAllHSB" );
  msg.setScope( "Breakout404" );
  msg.addArgument(0);
  msg.addArgument(0);
  msg.addArgument(0);
  lithne.send( msg );

  msg = new Message();
  msg.setFunction("setCCTParameters");
  msg.setScope("Breakout404");
  msg.toXBeeAddress64( nm.getXBeeAddress64("CCT Ceiling Tiles") );
  for (int i = 0; i < 5; i++) {
    msg.addArgument(i);
    msg.addArgument(1);
    msg.addArgument(0);
    msg.addArgument(0);
  }
  lithne.send(msg);
}

