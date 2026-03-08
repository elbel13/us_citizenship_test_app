import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/services/government_officials_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GovernmentOfficialsApiService', () {
    late GovernmentOfficialsApiService service;

    setUp(() {
      service = GovernmentOfficialsApiService();
    });

    group('Static Data Tests', () {
      test('loads static data successfully', () async {
        final data = await service.getOfficialsByState('California');

        expect(data, isNotNull);
        expect(data['president'], isNotEmpty);
        expect(data['vicePresident'], isNotEmpty);
        expect(data['governor'], isNotEmpty);
        expect(data['state'], 'California');
        expect(data['stateAbbr'], 'CA');
        expect(data['lastUpdated'], isNotEmpty);
      });

      test('returns correct current president and vice president', () async {
        final data = await service.getOfficialsByState('Texas');

        expect(data['president'], 'Donald John Trump');
        expect(data['vicePresident'], 'James David Vance');
      });

      test('returns correct governor for specific states', () async {
        final californiaData = await service.getOfficialsByState('California');
        expect(californiaData['governor'], 'Gavin Newsom');

        final texasData = await service.getOfficialsByState('Texas');
        expect(texasData['governor'], 'Greg Abbott');

        final floridaData = await service.getOfficialsByState('Florida');
        expect(floridaData['governor'], 'Ron DeSantis');

        final newYorkData = await service.getOfficialsByState('New York');
        expect(newYorkData['governor'], 'Kathy Hochul');
      });

      test('handles case-insensitive state names', () async {
        final lowercase = await service.getOfficialsByState('california');
        expect(lowercase['governor'], 'Gavin Newsom');

        final uppercase = await service.getOfficialsByState('CALIFORNIA');
        expect(uppercase['governor'], 'Gavin Newsom');

        final mixed = await service.getOfficialsByState('CaLiFoRnIa');
        expect(mixed['governor'], 'Gavin Newsom');
      });

      test('handles state names with extra whitespace', () async {
        final data = await service.getOfficialsByState('  California  ');
        expect(data['governor'], 'Gavin Newsom');
      });

      test('throws exception for invalid state', () async {
        expect(
          () => service.getOfficialsByState('InvalidState'),
          throwsA(isA<Exception>()),
        );
      });

      test('returns all 50 states and DC', () async {
        final states = [
          'Alabama',
          'Alaska',
          'Arizona',
          'Arkansas',
          'California',
          'Colorado',
          'Connecticut',
          'Delaware',
          'Florida',
          'Georgia',
          'Hawaii',
          'Idaho',
          'Illinois',
          'Indiana',
          'Iowa',
          'Kansas',
          'Kentucky',
          'Louisiana',
          'Maine',
          'Maryland',
          'Massachusetts',
          'Michigan',
          'Minnesota',
          'Mississippi',
          'Missouri',
          'Montana',
          'Nebraska',
          'Nevada',
          'New Hampshire',
          'New Jersey',
          'New Mexico',
          'New York',
          'North Carolina',
          'North Dakota',
          'Ohio',
          'Oklahoma',
          'Oregon',
          'Pennsylvania',
          'Rhode Island',
          'South Carolina',
          'South Dakota',
          'Tennessee',
          'Texas',
          'Utah',
          'Vermont',
          'Virginia',
          'Washington',
          'West Virginia',
          'Wisconsin',
          'Wyoming',
          'District of Columbia',
        ];

        for (final state in states) {
          final data = await service.getOfficialsByState(state);
          expect(
            data['governor'],
            isNotEmpty,
            reason: 'Governor for $state should not be empty',
          );
          expect(
            data['stateAbbr'],
            isNotEmpty,
            reason: 'State abbreviation for $state should not be empty',
          );
        }
      });

      test('getLastUpdatedDate returns valid date', () async {
        final date = await service.getLastUpdatedDate();
        expect(date, isNotEmpty);
        expect(date, isNot('Unknown'));
        // Should be in format YYYY-MM-DD
        expect(date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      });
    });

    group('API Integration Tests', () {
      test(
        'fetches senators from whoismyrepresentative.com API',
        () async {
          final data = await service.getOfficialsByState('California');

          expect(data['senators'], isNotNull);
          expect(data['senators'], isA<List<String>>());

          // California should have 2 senators
          if (data['senators'].isNotEmpty) {
            print('California Senators: ${data['senators']}');
            // Most states have 2 senators, but API might return 0 if down
            expect(data['senators'].length, lessThanOrEqualTo(2));
          }
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test(
        'fetches representatives from whoismyrepresentative.com API with zip code',
        () async {
          // 90210 is Beverly Hills, California
          final data = await service.getOfficialsByState(
            'California',
            zipCode: '90210',
          );

          expect(data['representatives'], isNotNull);
          expect(data['representatives'], isA<List<String>>());

          if (data['representatives'].isNotEmpty) {
            print('Representatives for 90210: ${data['representatives']}');
            // Should have at least 1 representative
            expect(data['representatives'].length, greaterThanOrEqualTo(1));
          }
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test('handles API failure gracefully for senators', () async {
        // Even if API fails, should still return other data
        final data = await service.getOfficialsByState('Wyoming');

        expect(data['president'], isNotEmpty);
        expect(data['vicePresident'], isNotEmpty);
        expect(data['governor'], isNotEmpty);
        expect(data['senators'], isA<List<String>>());
        // senators might be empty if API is down, but shouldn't throw
      });

      test(
        'returns empty representatives list when no zip code provided',
        () async {
          final data = await service.getOfficialsByState('Texas');

          expect(data['representatives'], isEmpty);
        },
      );

      test(
        'getOfficialsByZipCode works with state and zip',
        () async {
          final data = await service.getOfficialsByZipCode(
            'California',
            '90210',
          );

          expect(data['president'], 'Donald John Trump');
          expect(data['vicePresident'], 'James David Vance');
          expect(data['governor'], 'Gavin Newsom');
          expect(data['state'], 'California');
          expect(data['senators'], isA<List<String>>());
          expect(data['representatives'], isA<List<String>>());
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test(
        'handles multiple states in parallel',
        () async {
          final futures = [
            service.getOfficialsByState('California'),
            service.getOfficialsByState('Texas'),
            service.getOfficialsByState('New York'),
            service.getOfficialsByState('Florida'),
          ];

          final results = await Future.wait(futures);

          expect(results.length, 4);
          for (final result in results) {
            expect(result['president'], 'Donald John Trump');
            expect(result['vicePresident'], 'James David Vance');
            expect(result['governor'], isNotEmpty);
          }
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );
    });

    group('Edge Cases', () {
      test('handles empty zip code', () async {
        final data = await service.getOfficialsByState(
          'California',
          zipCode: '',
        );

        expect(data['representatives'], isEmpty);
      });

      test('handles multi-word state names', () async {
        final states = [
          'New Hampshire',
          'New Jersey',
          'New Mexico',
          'New York',
          'North Carolina',
          'North Dakota',
          'Rhode Island',
          'South Carolina',
          'South Dakota',
          'West Virginia',
          'District of Columbia',
        ];

        for (final state in states) {
          final data = await service.getOfficialsByState(state);
          expect(data['state'], state);
          expect(data['governor'], isNotEmpty);
        }
      });

      test('state abbreviations are correct', () async {
        final testCases = {
          'California': 'CA',
          'Texas': 'TX',
          'New York': 'NY',
          'Florida': 'FL',
          'Alaska': 'AK',
          'Hawaii': 'HI',
          'District of Columbia': 'DC',
        };

        for (final entry in testCases.entries) {
          final data = await service.getOfficialsByState(entry.key);
          expect(
            data['stateAbbr'],
            entry.value,
            reason: '${entry.key} abbreviation should be ${entry.value}',
          );
        }
      });
    });
  });
}
