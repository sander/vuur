void exit() {
  println("exiting");
  writer.flush();
  writer.close();
  super.exit();
}
