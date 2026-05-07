import 'package:flutter_test/flutter_test.dart';
import 'package:hamster_crm_app/core/database/app_database.dart';
import 'package:hamster_crm_app/data/repositories/crm_repository.dart';
import 'package:hamster_crm_app/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('Hamster CRM renders MVP navigation', (tester) async {
    sqfliteFfiInit();
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );

    await tester.pumpWidget(HamsterCrmApp(repository: CrmRepository(database)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('뵤펫'), findsOneWidget);
    expect(find.text('대시보드'), findsWidgets);
    expect(find.text('고객등록'), findsOneWidget);
    expect(find.text('고객DB'), findsWidgets);
    expect(find.text('가망고객'), findsWidgets);

    await database.close();
  });
}
