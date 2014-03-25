class Point {
  int indicatorColor;
  float velocity;
  float x;
  float y;
  float px;
  float py;
  int lastMove;
  boolean updated;
  
  void setTo(Point point) {
    px = x = point.x;
    py = y = point.y;
  }

  void moveTo(IntList points) {
    float f = 1.0 / points.size();
    x = y = 0.0;
    for (int i = 0; i < points.size(); i++) {
      float[] pos = position(points.get(i));
      x += f * pos[0];
      y += f * pos[1];
    }
    if (lastMove != 0 && !(px == x && py == y)) {
      float g = sqrt(sq(x - px) + sq(y - py));
      if (g > 0) g = 1.0 / g;
      g = g * velocity; 
      x = px + g * (x - px);
      y = py + g * (y - py);
    }
    lastMove = millis();
    px = x;
    py = y;
    updated = true;
  }

  float[] toFloatArray() {
    float[] result = {
      x, y
    };
    return result;
  }

  void draw(int size) {
    ellipseMode(CENTER);
    fill(getColor());
    stroke(indicatorColor);
    strokeWeight(5);
    ellipse(x * size, y * size, 20, 20);
  }

  color getColor() {
    int[] hsb = xyToHSB(map(x, 0.5, 3.5, 0.0, 1.0), map(y, 0.5, 3.5, 0.0, 1.0));
    return color(hsb[0], hsb[1], hsb[2]);
  }

  boolean equals(Point p) {
    return x == p.x && y == p.y;
  }

  float[] position(int i) {
    float[] result = {
      (i / 4) + 0.5, (i % 4) + 0.5
    };
    return result;
  }
}

