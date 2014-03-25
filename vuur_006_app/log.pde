PrintWriter writer;
PrintWriter table;

void initLog() {
  String timeString = "" + (System.currentTimeMillis() / 1000);

  table = createWriter("../data/table-" + timeString + ".csv");

  addColumn("Log key");
  addColumn("Timestamp");
  addColumn("Sending to Breakout");
  addColumn("Some pads activated");
  for (int i = 0; i < 16; i++) {
    addColumn("Pad " + i + " activated");
  }
  addColumn("Color hue");
  addColumn("Color saturation");
  addColumn("Color brightness");
  addColumn("Preview hue");
  addColumn("Preview saturation");
  addColumn("Preview brightness");
  addColumn("Breathe");
  addColumn("Points");
  addColumn("Width");
  addColumn("Effect brightness");
  addColumn("Ceiling");
  addColumn("Loudness");
  addColumn("Motion");
  addColumn("Fade interval");
  for (int i = 0; i < 37; i++) {
    addColumn("sizedParameter " + i);
  }
  table.println();

  writer = createWriter("../data/log-" + timeString + ".txt");
  log("time", timeString);
}

void addColumn(String name, boolean comma) {
  table.print('"' + name + '"' + (comma ? "," : ""));
}
void addColumn(String name) {
  addColumn(name, true);
}

void log(String key, String value) {
  String line = System.currentTimeMillis() + ": " + key + ": " + value;
  writer.println(line);
  println(line);

  table.print("\"" + key + "\",");
  long[] row = new long[3 + 16 + 6 + 8 + 37];
  int n = 0;
  row[n++] = System.currentTimeMillis();
  row[n++] = int(on);
  row[n++] = int(surface.activated().size() > 0);
  for (int i = 0; i < nPads; i++)
    row[n++] = int(pads[i].activated);
  row[n++] = message.hue1;
  row[n++] = message.sat1;
  row[n++] = message.bri1;
  row[n++] = message.phue;
  row[n++] = message.psat;
  row[n++] = message.pbri;
  row[n++] = message.breathe;
  row[n++] = points;
  row[n++] = size;
  row[n++] = round(float(message.bri1) / 100.0 * points);
  row[n++] = int(points < CEILING_THRESHOLD);
  row[n++] = loudness;
  row[n++] = motion;
  row[n++] = fadeInterval;
  for (int i = 0; i < 37; i++) {
    row[n++] = parameterArray[i];
  }
  addRows(row);
  table.println();
}

void addRows(long[] values) {
  for (int i = 0; i < values.length; i++) {
    table.print(values[i] + ",");
  }
}

void log(String key, int value) {
  log(key, Integer.toString(value));
}

void exit() {
  println("exiting");
  writer.flush();
  writer.close();
  table.flush();
  table.close();
  super.exit();
}
