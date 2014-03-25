class Debouncer<T> {
  long lastDebounceTime = 0;
  long delay = 200;
  T lastState;
  T state;

  boolean update(T reading) {
    if (!reading.equals(lastState)) {
      lastDebounceTime = millis();
      lastState = reading;
    }
    if ((millis() - lastDebounceTime) > delay) {
      if (!reading.equals(state)) {
        state = reading;
        return true;
      }
    }
    return false;
  }
  
  T get() {
    return state;
  }
}
