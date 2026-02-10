import 'package:flutter/material.dart';
import 'package:marfeel_sdk/marfeel_sdk.dart';

import '../data/articles.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Article article;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      article = ModalRoute.of(context)!.settings.arguments as Article;
      CompassTracking.trackNewPage(article.url, rs: article.rs);
      CompassTracking.setPageVar('category', article.category);
      CompassTracking.setPageMetric('wordCount', article.wordCount);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    CompassTracking.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: CompassScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(article.imageUrl,
                height: 250, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(article.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(article.body,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => CompassTracking.trackConversion(
                'article_read',
                options: const ConversionOptions(scope: ConversionScope.page),
              ),
              child: const Text('Track Article Read'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  CompassTracking.addUserSegment(article.category),
              child: Text('Add Segment: ${article.category}'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => CompassTracking.trackConversion(
                'engagement',
                options: ConversionOptions(
                  initiator: 'article_button',
                  id: article.id,
                  value: '1',
                  meta: {'category': article.category},
                  scope: ConversionScope.session,
                ),
              ),
              child: const Text('Track Full Conversion'),
            ),
          ],
        ),
      ),
    );
  }
}
