import 'package:interface_stage/features/card_reader/data/datasources/taka_usb_data_source.dart';
import 'package:interface_stage/features/card_reader/data/repositories/taka_card_reader_repository.dart';
import 'package:interface_stage/features/card_reader/domain/repositories/card_reader_repository.dart';
import 'package:interface_stage/features/card_reader/domain/usecases/connect_card_reader.dart';
import 'package:interface_stage/features/card_reader/domain/usecases/disconnect_card_reader.dart';
import 'package:interface_stage/features/card_reader/domain/usecases/read_card.dart';
import 'package:interface_stage/features/referentiel/data/datasources/referentiel_remote_data_source.dart';
import 'package:interface_stage/features/referentiel/data/repositories/referentiel_repository_impl.dart';
import 'package:interface_stage/features/referentiel/domain/repositories/referentiel_repository.dart';
import 'package:interface_stage/features/referentiel/domain/usecases/fetch_cim10_referentiel.dart';
import 'package:interface_stage/features/referentiel/domain/usecases/fetch_products_by_category.dart';
import 'package:interface_stage/features/referentiel/domain/usecases/fetch_referentiel_items.dart';
import 'package:interface_stage/features/validation/data/datasources/protected_api_remote_data_source.dart';
import 'package:interface_stage/features/validation/data/repositories/protected_api_validator_repository_impl.dart';
import 'package:interface_stage/features/validation/data/repositories/user_session_auth_repository.dart';
import 'package:interface_stage/features/validation/domain/repositories/auth_session_repository.dart';
import 'package:interface_stage/features/validation/domain/repositories/protected_api_validator_repository.dart';
import 'package:interface_stage/features/validation/domain/usecases/validate_qr_token.dart';

class AppInjection {
  AppInjection._();

  static final TakaUsbDataSource _takaUsbDataSource = TakaUsbDataSource();

  static final CardReaderRepository _cardReaderRepository =
      TakaCardReaderRepository(_takaUsbDataSource);

  static final ConnectCardReader connectCardReader =
      ConnectCardReader(_cardReaderRepository);

  static final ReadCard readCard = ReadCard(_cardReaderRepository);

  static final DisconnectCardReader disconnectCardReader =
      DisconnectCardReader(_cardReaderRepository);

  static final ReferentielRemoteDataSource _referentielRemoteDataSource =
      ReferentielRemoteDataSource();

  static final ReferentielRepository _referentielRepository =
      ReferentielRepositoryImpl(_referentielRemoteDataSource);

  static final FetchReferentielItems fetchReferentielItems =
      FetchReferentielItems(_referentielRepository);

  static final FetchCim10Referentiel fetchCim10Referentiel =
      FetchCim10Referentiel(_referentielRepository);

  static final FetchProductsByCategory fetchProductsByCategory =
      FetchProductsByCategory(_referentielRepository);

  static final ProtectedApiRemoteDataSource _protectedApiRemoteDataSource =
      ProtectedApiRemoteDataSource();

  static final ProtectedApiValidatorRepository _protectedApiValidatorRepository =
      ProtectedApiValidatorRepositoryImpl(_protectedApiRemoteDataSource);

  static final AuthSessionRepository _authSessionRepository =
      UserSessionAuthRepository();

  static final ValidateQrToken validateQrToken = ValidateQrToken(
    _authSessionRepository,
    _protectedApiValidatorRepository,
  );
}
