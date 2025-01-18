String stringShortener(String string, int maxLength) {
  if (string.length <= maxLength) {
    return string;
  } else {
    string = string.replaceRange(maxLength - 4, null, "...");

    return string;
  }
}
