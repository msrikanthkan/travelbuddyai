import 'dart:convert';
import 'package:http/http.dart' as http;

/// Diagnostic tool to test Google Custom Search API configuration
class GoogleApiDiagnostic {
  static const String apiKey = 'AIzaSyDuhhxxbSDXCeTTt0ez1AnaT1SnyZsDYm8';
  static const String searchEngineId = 'c31e9fbb664594744';
  
  /// Test the API with a simple query
  static Future<void> testApi() async {
    print('\n🔧 === Google Custom Search API Diagnostic ===\n');
    
    // Test 1: Simple query
    print('📝 Test 1: Simple Search Query');
    await _testSimpleQuery();
    
    // Test 2: Check API key format
    print('\n📝 Test 2: API Key Validation');
    _validateApiKey();
    
    // Test 3: Check Search Engine ID format
    print('\n📝 Test 3: Search Engine ID Validation');
    _validateSearchEngineId();
    
    print('\n🔧 === Diagnostic Complete ===\n');
  }
  
  static Future<void> _testSimpleQuery() async {
    try {
      final testQuery = 'test';
      final url = Uri.parse(
        'https://customsearch.googleapis.com/customsearch/v1?'
        'key=$apiKey&'
        'cx=$searchEngineId&'
        'q=${Uri.encodeQueryComponent(testQuery)}'
      );
      
      print('🌐 Request URL: ${url.toString().replaceAll(apiKey, "API_KEY_HIDDEN")}');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      print('📡 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final searchInfo = data['searchInformation'];
        final totalResults = searchInfo?['totalResults'] ?? '0';
        print('✅ API is working!');
        print('📊 Total Results: $totalResults');
        print('🎉 Google Custom Search API is properly configured!');
      } else {
        print('❌ API Error: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        final error = errorData['error'];
        print('❌ Error Message: ${error['message']}');
        print('❌ Error Reason: ${error['errors'][0]['reason']}');
        
        _provideSolution(response.statusCode, error['message']);
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }
  
  static void _validateApiKey() {
    if (apiKey.startsWith('AIza')) {
      print('✅ API Key format looks correct (starts with AIza)');
    } else {
      print('❌ API Key format might be incorrect');
    }
    
    if (apiKey.length > 30) {
      print('✅ API Key length looks correct (${apiKey.length} characters)');
    } else {
      print('❌ API Key seems too short');
    }
  }
  
  static void _validateSearchEngineId() {
    if (searchEngineId.isNotEmpty) {
      print('✅ Search Engine ID is present (${searchEngineId.length} characters)');
    } else {
      print('❌ Search Engine ID is missing');
    }
  }
  
  static void _provideSolution(int statusCode, String message) {
    print('\n💡 === Suggested Solutions ===\n');
    
    if (statusCode == 403) {
      if (message.contains('does not have the access')) {
        print('🔧 Solution 1: Enable the API');
        print('   1. Go to: https://console.cloud.google.com/apis/library');
        print('   2. Search for "Custom Search API"');
        print('   3. Click "ENABLE"');
        print('   4. Wait 2-3 minutes');
        print('');
        print('🔧 Solution 2: Check API Key Restrictions');
        print('   1. Go to: https://console.cloud.google.com/apis/credentials');
        print('   2. Click on your API key');
        print('   3. Under "API restrictions", ensure "Custom Search API" is checked');
        print('   4. Click "Save"');
        print('');
        print('🔧 Solution 3: Verify Project');
        print('   1. Make sure you\'re in the correct Google Cloud project');
        print('   2. The API key and enabled APIs must be in the SAME project');
        print('');
        print('🔧 Solution 4: Create New API Key');
        print('   1. Go to: https://console.cloud.google.com/apis/credentials');
        print('   2. Click "Create Credentials" > "API Key"');
        print('   3. Copy the new key');
        print('   4. Update the code with the new key');
      } else if (message.contains('billing')) {
        print('🔧 Solution: Enable Billing');
        print('   1. Go to: https://console.cloud.google.com/billing');
        print('   2. Link a billing account (free tier available)');
        print('   3. You get 100 free queries per day');
      }
    } else if (statusCode == 400) {
      print('🔧 Solution: Check Search Engine ID');
      print('   1. Go to: https://programmablesearchengine.google.com/');
      print('   2. Click on your search engine');
      print('   3. Copy the "Search engine ID"');
      print('   4. Update the code with the correct ID');
    } else if (statusCode == 429) {
      print('🔧 Solution: Rate Limit Exceeded');
      print('   1. You\'ve exceeded 100 queries per day (free tier)');
      print('   2. Wait until tomorrow, or');
      print('   3. Enable billing for more queries');
    }
  }
}

// Made with Bob
