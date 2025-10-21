
import 'package:flutter_dotenv/flutter_dotenv.dart';

late final String kBaseUrl;

void initializeConfig() {
  kBaseUrl = dotenv.env['API_BASE_URL']!;
}


