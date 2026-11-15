import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Type 2: Factory ML Wastage Business Logic Tests', () {
    test('Calculates yield and wastage percentage correctly', () {
      const double inputQty = 1000.0;
      const double outputQty = 945.0;
      final wastageQty = inputQty - outputQty;
      final yieldPct = (outputQty / inputQty) * 100;
      final wastePct = (wastageQty / inputQty) * 100;

      expect(wastageQty, 55.0);
      expect(yieldPct, 94.5);
      expect(wastePct, 5.5);
      expect(yieldPct + wastePct, 100.0);
    });

    test('Efficiency grade assignment follows factory standards', () {
      String getGrade(double yieldPct) {
        if (yieldPct >= 95) return 'A+';
        if (yieldPct >= 90) return 'A';
        if (yieldPct >= 80) return 'B';
        if (yieldPct >= 70) return 'C';
        return 'D';
      }

      expect(getGrade(96.2), 'A+');
      expect(getGrade(92.0), 'A');
      expect(getGrade(85.4), 'B');
      expect(getGrade(72.1), 'C');
      expect(getGrade(58.0), 'D');
    });

    test('Human-readable alert severity labels are verified', () {
      String getManagerAlertTitle(int anomalyCount) {
        if (anomalyCount == 0) return 'All Stages Normal';
        return 'High Scrap & Waste Alert ($anomalyCount Stage${anomalyCount > 1 ? 's' : ''} Need Attention)';
      }

      expect(getManagerAlertTitle(0), 'All Stages Normal');
      expect(getManagerAlertTitle(1), 'High Scrap & Waste Alert (1 Stage Need Attention)');
      expect(getManagerAlertTitle(3), 'High Scrap & Waste Alert (3 Stages Need Attention)');
    });
  });
}

