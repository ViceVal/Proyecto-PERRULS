import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perruls_app/main.dart';
void main() {
  testWidgets('PerrulsApp muestra pantalla principal correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(PerrulsApp());

    expect(find.text('Mascotas Perruls'), findsOneWidget);
    
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpAndSettle();
    
    expect(find.byType(ListTile), findsAtLeast(1));
  });

  testWidgets('Búsqueda de mascotas funciona correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(PerrulsApp());
    
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Charlie');
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
  });

  testWidgets('Tap en mascota navega a pantalla de detalle', (WidgetTester tester) async {
    await tester.pumpWidget(PerrulsApp());
    
    await tester.pumpAndSettle();
    
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    
    expect(find.byType(AppBar), findsOneWidget);
  });
}