import 'package:hamster_crm_app/data/repositories/crm_repository.dart';

CrmStore createPlatformCrmStore() => InMemoryCrmRepository.seeded();
