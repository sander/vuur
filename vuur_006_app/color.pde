int[] xyToHSB(float x, float y) // Range 0-1
{
  int[] hsb = {
    255, 255, 255
  };

  // First calc saturation based on the distance to the centre.
  float dx = abs(x - 0.5);
  float dy = abs(y - 0.5);
  float d = sqrt( pow(dx, 2)+pow(dy, 2)  );
  d = constrain(d, 0, 0.5); // d may go up to 0.7 or so, so we take the horizontal max dist as max.
  // If we wish to start desaturation not from the edge, but further inwards, this value may be reduced; for instance to 3 or 2
  float sat = map(d, 0, 0.5, 0, 255); // map distance to centre to the saturation
  hsb[1] = int(sat); // Saturation:
  //println("Calculated d:" + d + ", and based Saturation on that: " + sat);
  // Now calculate the color
  // This is based on the angular position of the XY in relation to the centre

  PVector vect = new PVector(x-0.5, y-0.5);

  float heading = vect.heading();
  float ang = degrees(heading);
  if ( ang < 0 ) {
    ang += 360;
  }
  float hue = map(ang, 0, 360, 0, 255);
  hsb[0] = int(hue);
  //println("Calculated a:" + ang + " based on heading: "+heading+", and based Hue on that: " + hue);

  // We keep max bright because this is calced later on
  return hsb;
}
