import '../repositories/card_reader_repository.dart';

class ConnectCardReader {
  ConnectCardReader(this._repository);

  final CardReaderRepository _repository;

  Future<bool> call() => _repository.connect();
}
