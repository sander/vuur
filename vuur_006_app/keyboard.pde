void saveCalibration() {
  JSONObject json = new JSONObject();
  JSONArray min = new JSONArray();
  JSONArray max = new JSONArray();
  for (int i = 0; i < nPads; i++) {
    min.setInt(i, pads[i].min);
    max.setInt(i, pads[i].max);
  }
  json.setJSONArray("min", min);
  json.setJSONArray("max", max);
  json.setFloat("threshold", threshold);
  saveJSONObject(json, CALIBRATION_FILE);
}

void keyPressed() {
  switch (key) {
  case ' ':
    switch (state) {
    case State.CALIBRATE_NOT_TOUCHED:
      state = State.CALIBRATE_TOUCHED;
      for (int i = 0; i < nPads; i++)
        pads[i].max = pads[i].min + 1;
      break;
    case State.CALIBRATE_TOUCHED:
      state = State.RUNNING;
      saveCalibration();
      break;
    case State.RUNNING:
      state = State.RUNNING;
      for (int i = 0; i < nPads; i++) {
        pads[i].min = pads[i].max = 0;
      }
      state = State.CALIBRATE_NOT_TOUCHED;
      break;
    }
    break;
  case 'o':
    on = !on;
    message.update = true;
    break;
  case 'r':
    reset = true;
    break;
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
  case '9':
    threshold = (int(key) - 48) / 10.0;
    break;
  case 'd':
    drawing = !drawing;
    cached_status = null;
    cached_mode = null;
    background(0);
    break;
  case 'u':
    turnOff();
    on = false;
    message.update = true;
    break;
  case 'c':
    onTheSpotCalibration = true;
    //state = State.CALIBRATE_NOT_TOUCHED;
    for (int i = 0; i < nPads; i++)
      pads[i].onTheSpotPreviousMin = pads[i].min;
    set_minima();
    log("recalibration", "minima reset, press y to confirm or n to cancel");
    print("was: ");
    for (int i = 0; i < nPads; i++)
      print(pads[i].onTheSpotPreviousMin + "\t");
    println();
    print("became: ");
    for (int i = 0; i < nPads; i++)
      print(pads[i].min + "\t");
    println();
    break;
  case 'y':
    onTheSpotCalibration = false;
    saveCalibration();
    //state = State.RUNNING;
    log("recalibration", "confirmed");
    break;
  case 'n':
    onTheSpotCalibration = false;
    //state = State.RUNNING;
    for (int i = 0; i < nPads; i++)
      pads[i].min = pads[i].onTheSpotPreviousMin;
    log("recalibration", "reverted");
    break;
  case 'm':
    recalibrateMaximaOnTheSpot = !recalibrateMaximaOnTheSpot;
    log("recalibrate maxima", "" + recalibrateMaximaOnTheSpot);
    break;
  default:
    switch (keyCode) {
    case 38: // arrow up
      fadeInterval += 100;
      log("fadeInterval", fadeInterval);
      break;
    case 40: // arrow down
      fadeInterval -= 100;
      log("fadeInterval", fadeInterval);
      break;
    }
  }
}
