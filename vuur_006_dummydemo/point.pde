class Point {
  int indicatorColor;
  float velocity;
  float x;
  float y;
  float px;
  float py;
  int lastMove;
  boolean updated;
  
  Point() {
  }
  
  Point(int i) {
    float[] pos = position(i);
    px = x = pos[0];
    py = y = pos[1];
  }
  
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
  
  void moveTo(float nx, float ny) {
    //println("moving to: " + nx);
    if (lastMove != 0 && !(px == nx && py == ny)) {
      float g = sqrt(sq(nx - px) + sq(ny - py));
      if (g > 0) g = 1.0 / g;
      g = g * velocity; 
      x = px + g * (nx - px);
      y = py + g * (ny - py);
    }
    lastMove = millis();
    px = x;
    py = y;
    updated = true;
  }
  
  void moveTo(Point p) {
    moveTo(p.px, p.py);
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
  
  float distance(int i) {
    float[] pos = position(i);
    return sqrt(sq(pos[0] - x) + sq(pos[1] - y));
  }
  
  float distance(Point p) {
    return sqrt(sq(p.x - x) + sq(p.y - y));
  }
}

