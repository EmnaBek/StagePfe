abstract class CardReaderRepository {
  Future<bool> connect();

  Future<String> readCard();

  Future<void> disconnect();
}
