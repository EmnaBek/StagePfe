import '../../domain/repositories/card_reader_repository.dart';
import '../datasources/taka_usb_data_source.dart';

class TakaCardReaderRepository implements CardReaderRepository {
  TakaCardReaderRepository(this._dataSource);

  final TakaUsbDataSource _dataSource;

  @override
  Future<bool> connect() => _dataSource.connect();

  @override
  Future<String> readCard() => _dataSource.readCard();

  @override
  Future<void> disconnect() => _dataSource.disconnect();
}
