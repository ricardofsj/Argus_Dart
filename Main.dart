import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

void main() => runApp(NewsAggregatorApp());

class NewsAggregatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agregador de Notícias',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NewsListScreen(),
    );
  }
}

class NewsListScreen extends StatefulWidget {
  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  // Lista com URLs dos feeds RSS/Atom desejados
  final List<String> feedUrls = [
    'https://feeds.feedburner.com/TheHackersNews', // The Hacker News
    'https://us-cert.cisa.gov/ncas/alerts.xml',  // CISA
    'https://malpedia.caad.fkie.fraunhofer.de/api/raw/atom' // Malpedia (exemplo, verificar URL atual)
  ];

  late Future<List<RssItem>> _newsItems;

  Future<List<RssItem>> fetchNews() async {
    List<RssItem> allItems = [];
    for (var url in feedUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          if (url.contains('atom')) {
            final atomFeed = AtomFeed.parse(response.body);
            allItems.addAll(atomFeed.items);
          } else {
            final rssFeed = RssFeed.parse(response.body);
            allItems.addAll(rssFeed.items ?? []);
          }
        }
      } catch (e) {
        // Pode registrar erro ou ignorar feed inválido
      }
    }
    // Opcional: ordenar por data (mais recente primeiro)
    allItems.sort((a, b) => (b.pubDate ?? DateTime(0)).compareTo(a.pubDate ?? DateTime(0)));
    return allItems;
  }

  @override
  void initState() {
    super.initState();
    _newsItems = fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregador de Notícias'),
      ),
      body: FutureBuilder<List<RssItem>>(
        future: _newsItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar notícias'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhuma notícia encontrada'));
          }
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.title ?? 'Sem título'),
                subtitle: Text(item.pubDate?.toLocal().toString() ?? ''),
                onTap: () {
                  // Abrir link da notícia ou abrir detalhes
                },
              );
            },
          );
        },
      ),
    );
  }
}
