import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapping/model/model.dart';
import 'dart:convert';

class RecentStakeholdersManager {
  static const String _recentStakeholdersKey = 'recent_stakeholders';
  static const int _maxRecentStakeholders = 5;

  // Method to add a stakeholder to recent list
  static Future<void> addToRecentStakeholders(Stakeholder stakeholder) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> recentStakeholdersJson = prefs.getStringList(_recentStakeholdersKey) ?? [];
      
      Map<String, dynamic> stakeholderData = {
        'fullName': stakeholder.fullName,
        'association': stakeholder.association,
        'lg': stakeholder.lg,
        'ward': stakeholder.ward,
        'phoneNumber': stakeholder.phoneNumber,
        'email': stakeholder.email,
        'whatsappNumber': stakeholder.whatsappNumber,
        'levelOfAdministration': stakeholder.levelOfAdministration,
        'country': stakeholder.country,
        'state': stakeholder.state,
      };
      
      String stakeholderJsonString = jsonEncode(stakeholderData);
      
      // Remove if already exists to avoid duplicates
      recentStakeholdersJson.removeWhere((json) {
        Map<String, dynamic> existing = jsonDecode(json);
        return existing['fullName'] == stakeholder.fullName && 
               existing['phoneNumber'] == stakeholder.phoneNumber;
      });
      
      // Add to beginning of list
      recentStakeholdersJson.insert(0, stakeholderJsonString);
      
      // Keep only last 5 items
      if (recentStakeholdersJson.length > _maxRecentStakeholders) {
        recentStakeholdersJson = recentStakeholdersJson.sublist(0, _maxRecentStakeholders);
      }
      
      await prefs.setStringList(_recentStakeholdersKey, recentStakeholdersJson);
    } catch (e) {
      print('Error adding to recent stakeholders: $e');
    }
  }

  // Method to get recent stakeholders
  static Future<List<Map<String, dynamic>>> getRecentStakeholders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? recentStakeholdersJson = prefs.getStringList(_recentStakeholdersKey);
      
      if (recentStakeholdersJson != null) {
        return recentStakeholdersJson
            .map((json) => jsonDecode(json) as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error loading recent stakeholders: $e');
      return [];
    }
  }

  // Method to clear recent stakeholders
  static Future<void> clearRecentStakeholders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentStakeholdersKey);
    } catch (e) {
      print('Error clearing recent stakeholders: $e');
    }
  }
}
