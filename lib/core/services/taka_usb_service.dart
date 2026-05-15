import 'package:interface_stage/app/injection.dart';

@Deprecated('Use card_reader domain use cases from AppInjection instead.')
class TakaUsbService {
  Future<bool> connect() => AppInjection.connectCardReader();

  Future<String> readCard() => AppInjection.readCard();

  Future<void> disconnect() => AppInjection.disconnectCardReader();
}
