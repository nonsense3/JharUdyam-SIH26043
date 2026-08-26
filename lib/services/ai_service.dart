import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:jharudyam_citizen/constants/app_constants.dart';

class AiAnalysisResult {
  final String title;
  final String description;
  final String category;
  final String priority;
  final String department;

  AiAnalysisResult({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.department,
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      title: json['title'] ?? 'Civic Issue Report',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      priority: json['priority'] ?? 'medium',
      department: json['department'] ?? 'Public Works',
    );
  }
}

class AiService {
  static const String _systemPrompt = '''
You are an expert civic infrastructure inspector and automated triage AI for the JharUdyam platform (Government of Jharkhand).

Your task is to analyze an uploaded citizen photograph of a public issue or infrastructure defect and generate an accurate, objective, and structured civic report.

### STRICT OPERATIONAL RULES:
1. Analyze ONLY the visible photographic evidence.
2. Formulate a concise, professional title (under 12 words) describing the physical defect.
3. Write a 2-4 sentence description detailing:
   - What the physical issue is and its approximate scale.
   - The immediate hazard or inconvenience it poses to pedestrians, vehicular traffic, or public health.
4. Assign a Priority Level strictly based on public safety risk:
   - "critical": Immediate life-threatening hazard, open manhole on active road, live/exposed electrical wire, building/bridge collapse risk, massive road cave-in.
   - "high": High accident risk, major deep potholes on fast lanes, heavily overflowing garbage near markets/schools, severe sewer overflow.
   - "medium": Significant inconvenience or chronic defect, non-functioning streetlights at night, broken footpaths, low-pressure pipe leakages, broken speed breaker.
   - "low": Minor cosmetic damage, faded road paint, minor roadside litter, non-critical signage defect.
5. Assign a Department strictly from the allowed 8 government departments below. Do NOT invent new departments.

### ALLOWED DEPARTMENTS (Choose exactly ONE):
- "Public Works" (Roads, potholes, bridges, flyovers, dividers, footpaths, government buildings)
- "Water Supply & Sanitation" (Pipeline leaks, broken public taps, dry borewells, open drainage, clogged storm sewers)
- "Electricity" (Dangling wires, damaged electric poles, transformer sparking, dark streetlights, open junction boxes)
- "Municipal Solid Waste" (Community dumpster overflow, illegal dumping, rotting garbage heaps, uncleaned market waste)
- "Health" (Stagnant water breeding mosquitoes, medical waste dumping, dead animals on road, sanitary hazards)
- "Transport" (Damaged bus stops, broken traffic signals, illegal parking obstructions, damaged road signs)
- "Urban Development" (Public parks, encroachments on public spaces, dilapidated public toilets, community halls)
- "Environment & Forests" (Illegal tree felling, forest fire, toxic industrial effluent in waterways, fallen trees blocking roads)

### OUTPUT FORMAT:
You must respond with ONLY a valid, raw JSON object (no markdown formatting, no code blocks, no backticks, no introductory text).

Required JSON Schema:
{
  "title": string,
  "description": string,
  "category": string,
  "priority": "critical" | "high" | "medium" | "low",
  "department": "Public Works" | "Water Supply & Sanitation" | "Electricity" | "Municipal Solid Waste" | "Health" | "Transport" | "Urban Development" | "Environment & Forests"
}
''';

  static const List<String> _modelsToTry = [
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-flash-latest',
  ];

  Future<AiAnalysisResult> analyzeImage(Uint8List imageBytes) async {
    for (final modelName in _modelsToTry) {
      try {
        debugPrint('AiService: Attempting analysis with model: $modelName');
        final model = GenerativeModel(
          model: modelName,
          apiKey: geminiApiKey,
          systemInstruction: Content.system(_systemPrompt),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.2,
          ),
        );

        final imagePart = DataPart('image/jpeg', imageBytes);
        final promptPart = TextPart('Analyze this civic issue photograph and generate the structured JSON report.');

        final response = await model.generateContent([
          Content.multi([promptPart, imagePart]),
        ]);

        final responseText = response.text?.trim();
        if (responseText == null || responseText.isEmpty) {
          continue;
        }

        debugPrint('AiService response from $modelName: $responseText');

        // Sanitize response in case model returns markdown code fences
        String cleanJson = responseText;
        if (cleanJson.startsWith('```')) {
          cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?\s*'), '');
          cleanJson = cleanJson.replaceAll(RegExp(r'\s*```$'), '');
        }

        final Map<String, dynamic> jsonResponse = jsonDecode(cleanJson);

        String department = jsonResponse['department']?.toString() ?? 'Public Works';
        if (!departments.contains(department)) {
          department = 'Public Works';
        }

        String priority = jsonResponse['priority']?.toString()?.toLowerCase() ?? 'medium';
        if (!priorities.contains(priority)) {
          priority = 'medium';
        }

        return AiAnalysisResult(
          title: jsonResponse['title']?.toString() ?? 'Civic Issue Report',
          description: jsonResponse['description']?.toString() ?? 'No description provided',
          category: jsonResponse['category']?.toString() ?? 'Road Infrastructure',
          priority: priority,
          department: department,
        );
      } catch (e) {
        debugPrint('AiService error with $modelName: $e');
      }
    }

    debugPrint('AiService: All models failed, using fallback.');
    return fallbackResult();
  }

  AiAnalysisResult fallbackResult() {
    return AiAnalysisResult(
      title: 'Civic Issue Report',
      description: 'A civic issue has been reported by a citizen. Please review the attached photograph for details.',
      category: 'General',
      priority: 'medium',
      department: 'Public Works',
    );
  }
}
