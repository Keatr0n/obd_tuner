typedef DataAwaiter = Future<String?> Function(Pattern pattern, [bool asHex]);

abstract class IOBDMessage {
  /// This the string payload to be sent over bluetooth
  String get payload;

  /// An optional pattern to match for the expected response
  /// The expectedResponse will indicate that the message went through correctly.
  Pattern? get expectedResponse;

  // num parseResponseString(String response);
  Future<dynamic> parseResponse(DataAwaiter awaitData);
}
