void draw_palette() {
  noStroke();
  fill(0);
  rect(0, 0, SENSOR_DISPLAY[0] + SENSOR_DISPLAY[2], SENSOR_DISPLAY[1] + SENSOR_DISPLAY[3]);
  pushMatrix();
  translate(SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]);
  int width = 10;
  int size = SENSOR_DISPLAY[3] / 4;
  for (int i = 0; i < nPads; i++) {
    pushMatrix();
    translate(i / 4 * size, i % 4 * size);
    stroke(100);
    strokeWeight(width);
    rect(width / 2, width / 2, size - width, size - width);

    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    textFont(font);
    text(i, size / 2, size / 2);
    fill(0);

    popMatrix();
  }
  popMatrix();
}

void draw_sensed() {
  int size = SENSOR_DISPLAY[3] / 4;
  pushMatrix();
  translate(SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]);
  IntList sp = sensed_points();
  for (int i = 0; i < sp.size(); i++) {
    int p = sp.get(i);
    pushMatrix();
    translate(p / 4 * size, p % 4 * size);
    noStroke();
    fill(150);
    rect(0, 0, size, size);
    popMatrix();
  }
  popMatrix();
}

void draw_activated() {
  int size = SENSOR_DISPLAY[3] / 4;
  pushMatrix();
  translate(SENSOR_DISPLAY[0], SENSOR_DISPLAY[1]);
  IntList ap = surface.activated();
  for (int i = 0; i < ap.size(); i++) {
    int p = ap.get(i);
    ellipseMode(CENTER);
    stroke(255);
    strokeWeight(2);
    noFill();
    ellipse((p / 4 + 0.5) * size, (p % 4 + 0.5) * size, 20, 20);
  }
  preview.draw(size);
  center.draw(size);
  center2.draw(size);
  inspiration.draw(size);
  popMatrix();
}

String status() {
  StringBuilder s = new StringBuilder();
  s.append(state);
  s.append('\n');
  if (!receiving)
    s.append(" not");
  s.append("receiving values\nthreshold: ");
  s.append(threshold);
  s.append("\n<<<");
  s.append(points);
  s.append(" points>>>\n");
  s.append(touch_amount);
  s.append(" touches\nlast touch duration: ");
  s.append(last_touch_duration);
  s.append("\ndistance: ");
  s.append(touch_distance);
  s.append("\nmessages sent to lithne: ");
  s.append(sent);
  s.append("\nfade interval: ");
  s.append(fadeInterval);
  s.append("\nactivated: ");
  s.append(surface.numberOfActivatedPadsDuringInteraction());
  s.append("\nvelocity: ");
  s.append(center.velocity);
  s.append("\nsize: ");
  s.append(size);
  return s.toString();
}

void draw_status() {
  String st = status();
  if (cached_status == null || !st.equals(cached_status)) {
    int x = SENSOR_DISPLAY[0] + SENSOR_DISPLAY[2] + 30;
    int y = 10;
    int w = width - x;
    int h = SENSOR_DISPLAY[3];
    fill(0);
    noStroke();
    rect(x, SENSOR_DISPLAY[1], w, h);
    fill(255);
    textSize(12);
    textAlign(LEFT, TOP);
    textFont(font);
    text(st, x, y);
    cached_status = st;
  }
}

void draw_message() {
  pushMatrix();
  translate(MESSAGE_DISPLAY[0], MESSAGE_DISPLAY[1]);

  // background
  noStroke();
  fill(40);
  rect(0, 0, MESSAGE_DISPLAY[2], MESSAGE_DISPLAY[3]);

  int width = (MESSAGE_DISPLAY[2] - 20) / 15;

  noStroke();
  fill(message.hue1, message.sat1, message.bri1);
  rect(15 + width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20);
  fill(message.phue, message.psat, message.pbri);
  rect(15 + 3 * width, 10, 2 * width - 10, MESSAGE_DISPLAY[3] - 20);

  textSize(12);
  textAlign(CENTER, CENTER);
  textFont(font);
  fill(255);
  text("on\n" + Boolean.toString(on), 10 + 0.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("size\n" + Integer.toString(size), 10 + 11.5 * width, MESSAGE_DISPLAY[3] / 2);
  text("breathe\n" + Integer.toString(message.breathe), 10 + 12.5 * width, MESSAGE_DISPLAY[3] / 2);
  popMatrix();
}
