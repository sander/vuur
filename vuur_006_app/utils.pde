String charArrayToString(char[] arr) {
  StringBuffer result = new StringBuffer();
  for (int i = 0; i < arr.length; i++) {
    result.append( int(arr[i]) );
    result.append('\t');
  }
  return result.toString();
}

String arrayToString(int[] arr) {
  StringBuffer result = new StringBuffer();
  for (int i = 0; i < arr.length; i++) {
    result.append( arr[i] );
    result.append('\n');
  }
  return result.toString();
}
String intListToString(IntList arr) {
  StringBuffer result = new StringBuffer();
  for (int i = 0; i < arr.size(); i++) {
    result.append(arr.get(i));
    result.append(' ');
  }
  return result.toString();
}

boolean intListsEqual(IntList a, IntList b) {
  if (a.size() != b.size())
    return false;
  for (int i = 0; i < a.size(); i++)
    if (a.get(i) != b.get(i))
      return false;
  return true;
}

