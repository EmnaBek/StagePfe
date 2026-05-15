import '../repositories/card_reader_repository.dart';

class ReadCard {
  ReadCard(this._repository);

  final CardReaderRepository _repository;

  Future<String> call() => _repository.readCard();
}
