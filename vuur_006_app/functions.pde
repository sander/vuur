/**
*  This class is called FunctionTable (you can change the name if you want) and it implements MessageListener.
*  This means that any 'MessageEvent'-s from the Lithne class will be forwarded to this class (if it is registered as a
*  listener). You don't have to specifically request the Lithne library to check for available messages, this happens
*  automatically.
*  Whenever a MessageEvent is thrown, it calls the function 'messageEventReceived( MessageEvent event )' of all its
*  listeners. So, all you have to do, is also implement this function in your class. The class below provides an example
*  of this. If you understand the basics of this, you can make very object (class) listen to specific messages.
**/
public class FunctionTable implements MessageListener
{
  /**
  *  This is a basic constructor, that actually does nothing.
  **/
  FunctionTable(){}
  
  /**
  *  Whenever the Lithne library receives data from the XBee, this is converted into a Message object.
  *  The library then throws an event, which basically informs all of its listeners
  **/
  public void messageEventReceived( MessageEvent event )
  {
    //println(millis()+" Received message");
    //println("Message:"+event.getMessage().toString());
    
    /**
    *  To get the information from the message, you can use the following functions:
    *  > event.getMessage().toXBeeAddress64();       -  XBeeAddress64
    *  > event.getMessage().toXBeeAddress16();       -  XBeeAddress16
    *  > event.getMessage().fromXBeeAddress64();     -  XBeeAddress64
    *  > event.getMessage().fromXBeeAddress16();     -  XBeeAddress16
    *  > event.getMessage().getScope();              -  int
    *  > event.getMessage().getFunction();           -  int
    *  > event.getMessage().functionIs( String );    -  boolean
    *  > event.getMessage().getNumberOfArguments();  -  int
    *  > event.getMessage().getArgument( int );      -  int
    *  > event.getMessage().getArguments();          -  int[]
    *
    *  You can use this in different ways. You can either specifically check for the functions you wish
    *  to receive, and then call specific functions in your own code. (read further below)
    **/
    if (event.getMessage().functionIs("motion")) {
      log("motion", event.getMessage().getArgument(0));
    } else if (event.getMessage().functionIs("loudness")) {
      log("loudness", event.getMessage().getArgument(0));
    }
    /*
    if( event.getMessage().functionIs( "ledValue" ) )
    {
      if (event.getMessage().getNumberOfArguments() == 1)
      {
        println("Received function ledValue");
        println("\t The state of the LED is: " + event.getMessage().getArgument( 0 ));
      }
    }
    else if( event.getMessage().functionIs( "timedSender" ) )
    {
      if (event.getMessage().getNumberOfArguments() == 2)
      {
        println("Received function timedSender");
        println("\t the time running is: " +  + event.getMessage().getArgument( 0 ));
        println("\t and a random number: " +  + event.getMessage().getArgument( 1 ));
      }
    }
    else if( event.getMessage().functionIs( "error" ) )
    {
      println("This is an ERROR message.");
    }
    */
    /**
    *  Our you can choose to make a state machine, in which you loop through different possible cases.
    *  In essence, this is the same approach, but your code might look cleaner, with a lot less 'if' 
    *  statements
    **/
    
  }
}
