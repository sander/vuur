void exit() {
  println("exiting");
  writer.flush();
  writer.close();
  table.flush();
  table.close();
  //saveTable(table, "../data/table-" + timeString + ".csv");
  super.exit();
}
