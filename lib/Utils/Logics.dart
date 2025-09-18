String addLeadingZero(String input) {
  if (input.startsWith('0') && input.length > 1) {
    return input;
  } else if (input.length > 1) {
    return "0$input";
  }
  return input;
}
