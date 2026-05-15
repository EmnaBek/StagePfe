import '../repositories/card_reader_repository.dart';

class DisconnectCardReader {
  DisconnectCardReader(this._repository);

  final CardReaderRepository _repository;

  Future<void> call() => _repository.disconnect();
}
