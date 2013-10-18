const boolean debug = false;

void fun(int rec, String name) {
  if (debug) {
    Serial.print("fun " + name + " @ ");
    Serial.println(rec);
  }
  Lithne.setFunction(name);
  Lithne.setScope("Breakout404");
  Lithne.setRecipient(rec);
}

void arg(int a) {
  if (debug) {
    Serial.print("\targ ");
    Serial.println(a);
  }
  Lithne.addArgument(a);
}

void snd() {
  if (debug) Serial.println("\tsent");
  Lithne.send();
}
