import 'package:flutter_test/flutter_test.dart';
import 'package:final_project/app/constants/app_constants.dart';
import 'package:final_project/core/config/api_config.dart';

void main() {
  group('Type 1: Automated Unit & Sanity Verification Suite', () {
    test('Company Name strictly spelled "Buoy" across all constants', () {
      expect(AppConstants.companyName, 'Buoy');
      expect(AppConstants.appName, 'Buoy ERP');
      expect(AppConstants.copyright, contains('Buoy'));
      expect(AppConstants.companyName.toLowerCase(), isNot(contains('bouy')));
      expect(AppConstants.appName.toLowerCase(), isNot(contains('bouy')));
    });

    test('Production API Endpoint is secured and HTTPS', () {
      expect(ApiConfig.productionUrl, startsWith('https://'));
      expect(ApiConfig.productionUrl, contains('buoy-erp-main.vercel.app'));
    });

    test('App version and build number formatting is valid', () {
      expect(AppConstants.appVersion, matches(r'^\d+\.\d+\.\d+$'));
      expect(AppConstants.buildNumber, isPositive);
      expect(AppConstants.fullVersionString, startsWith('v'));
      expect(AppConstants.fullVersionString, contains('Build'));
    });
  });
}

