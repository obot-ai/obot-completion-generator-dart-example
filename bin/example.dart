import 'dart:io';

import 'package:obot_completion_generator/obot_completion_generator.dart';

void main(List<String> args) async {
  String host = "";
  String apiKey = "";
  String locale = "ja";

  for (var i = 0; i < args.length; i++) {
    if (i >= args.length - 1) {
      break;
    }
    if (args[i] == "--host") {
      host = args[i + 1];
    } else if (args[i] == "--key") {
      apiKey = args[i + 1];
    } else if (args[i] == "--locale") {
      locale = args[i + 1];
    }
  }

  Generator generator = Generator();

  print("Fetching [$locale] data from $host with API key $apiKey");
  Fetcher fetcher = Fetcher(
      apiKey: apiKey,
      getEndpoint: (String locale) {
        return "$host/input_completion/$locale/";
      });

  try {
    List<LocaleDataItem> localeData = await fetcher.fetch(locale);
    print("Fetched ${localeData.length} items: $localeData");

    generator.loadData(locale, localeData);
  } on FetchFailedException catch (e) {
    // statusCodeが200以外の場合発生される例外。responseBodyでレスポンスのボディにアクセスできる
    print("Failed to fetch data. Exception: $e");
    print("StatusCode: ${e.statusCode}, ResponseBody: ${e.responseBody}");
    return;
  } on UnexpectedResponseBodyException catch (e) {
    // statusCodeが200かどうかに関わらず、responseBodyは想定したUTF-8デコーダーでデコードできない場合発生される例外。statusCodeのみアクセスできる
    print("Unexpected response body. Exception: $e");
    print("StatusCode: ${e.statusCode}");
    return;
  }

  while (true) {
    print("Enter a keyword to get completions:");
    String input = stdin.readLineSync() ?? "";
    if (input.isEmpty) {
      break;
    }

    List<MatchedResultData> results =
        generator.generateCompletions(input, locale);
    print("Results:");
    for (var result in results) {
      print(result);
    }
  }
}
