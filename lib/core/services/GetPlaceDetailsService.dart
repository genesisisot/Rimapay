import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rimapay/core/Models/CountryStateLgaModel.dart';
import 'package:rimapay/core/Utils/En.dart';



class LocationDetailsService {
  final ProviderRef? ref;

  LocationDetailsService({this.ref});

  final Map<String, String> stateNameVariations = {"federal capital territory": "FCT", "abuja": "FCT", "fct": "FCT", "ondo": "Ondo State", "osun": "Osun State"};

  Future<LocationDetails?> getLocationDetailsFromPlaceId(String placeId) async {
    try {
      final uri = Uri.parse("https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$GOOGLE_API_KEY&fields=address_component");

      log("Fetching details for place ID: $placeId");

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['result'] != null) {
          final components = data['result']['address_components'] as List;

          String? state;
          String? lga;

          for (var component in components) {
            final types = component['types'] as List;

            if (types.contains('administrative_area_level_1')) {
              state = component['long_name'];
            }

            if (types.contains('administrative_area_level_2')) {
              lga = component['long_name'];
            }
          }

          if (state != null) {
            final normalizedState = _normalizeStateName(state);
            log("Original state: $state, Normalized state: $normalizedState");

            return LocationDetails(
              state: normalizedState,
              localGovernment: lga,
            );
          }
        }
      }

      return null;
    } catch (e) {
      log("Error fetching place details: $e");
      return null;
    }
  }

  String _normalizeStateName(String stateName) {
    final lowercase = stateName.toLowerCase();

    if (stateNameVariations.containsKey(lowercase)) {
      return stateNameVariations[lowercase]!;
    }

    return stateName;
  }

  CountryStateLgaModel? findMatchingState(String stateName, List<CountryStateLgaModel> locations) {
    final normalizedName = _normalizeStateName(stateName);

    try {
      return locations.firstWhere(
        (location) => location.state?.name?.toLowerCase() == normalizedName.toLowerCase(),
      );
    } catch (e) {
      log("State not found: $normalizedName");

      if (normalizedName.toLowerCase().contains("abuja") || normalizedName.toLowerCase().contains("fct") || normalizedName.toLowerCase().contains("federal capital")) {
        try {
          return locations.firstWhere(
            (location) => location.state?.name == "FCT",
          );
        } catch (e) {
          log("FCT not found even after normalization");
        }
      }

      return null;
    }
  }

  Local? findMatchingLGA(String lgaName, List<Local> locals) {
    if (lgaName.isEmpty || locals.isEmpty) return null;

    log("Attempting to match LGA: $lgaName");

    try {
      return locals.firstWhere(
        (local) => local.name?.toLowerCase() == lgaName.toLowerCase(),
      );
    } catch (e) {
      log("Exact LGA match not found, trying advanced matching...");

      String cleanedLgaName = lgaName.toLowerCase();
      final prefixesToRemove = [
        "abuja ",
        "federal capital territory ",
        "local government area",
        "local government",
        "lga",
        "metropolitan",
        "municipal",
        "district",
      ];

      for (var prefix in prefixesToRemove) {
        if (cleanedLgaName.contains(prefix)) {
          cleanedLgaName = cleanedLgaName.replaceAll(prefix, "").trim();
        }
      }

      try {
        return locals.firstWhere(
          (local) => local.name?.toLowerCase() == cleanedLgaName,
        );
      } catch (e) {
        try {
          return locals.firstWhere((local) => local.name != null && (cleanedLgaName.contains(local.name!.toLowerCase()) || local.name!.toLowerCase().contains(cleanedLgaName)));
        } catch (e) {
          Local? bestMatch;
          int highestScore = 0;

          for (var local in locals) {
            if (local.name == null) continue;

            final localName = local.name!.toLowerCase();
            int score = calculateMatchScore(cleanedLgaName, localName);

            if (score > highestScore) {
              highestScore = score;
              bestMatch = local;
            }
          }

          if (highestScore >= 3) {
            log("Found fuzzy match: ${bestMatch?.name} with score $highestScore");
            return bestMatch;
          }

          log("No matching LGA found for: $lgaName");
          return null;
        }
      }
    }
  }

  int calculateMatchScore(String s1, String s2) {
    final words1 = s1.split(" ")..removeWhere((w) => w.length < 3);
    final words2 = s2.split(" ")..removeWhere((w) => w.length < 3);

    int score = 0;

    for (var word1 in words1) {
      for (var word2 in words2) {
        if (word1 == word2) {
          score += 2;
          continue;
        }

        if (word1.length > 3 && word2.length > 3) {
          if (word1.contains(word2) || word2.contains(word1)) {
            score += 1;
          }
        }
      }
    }

    if (s1.contains(s2) || s2.contains(s1)) {
      score += 3;
    }

    int prefixLength = 0;
    while (prefixLength < s1.length && prefixLength < s2.length && s1[prefixLength] == s2[prefixLength]) {
      prefixLength++;
    }

    if (prefixLength >= 4) {
      score += 2;
    }

    return score;
  }
}

class LocationDetails {
  final String state;
  final String? localGovernment;

  LocationDetails({
    required this.state,
    this.localGovernment,
  });

  @override
  String toString() => 'State: $state, LGA: $localGovernment';
}

final locationDetailsServiceProvider = Provider<LocationDetailsService>((ref) {
  return LocationDetailsService(ref: ref);
});

final locationDetailsProvider = FutureProvider.family<LocationDetails?, String>((ref, placeId) async {
  return await ref.watch(locationDetailsServiceProvider).getLocationDetailsFromPlaceId(placeId);
});
