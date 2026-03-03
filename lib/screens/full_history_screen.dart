import 'package:flutter/material.dart';
import 'package:my_app/widgets/layout.dart';

class FullHistoryScreen extends StatelessWidget {
  const FullHistoryScreen({Key? key}) : super(key: key);

  static const List<Map<String, String>> historyItems = [
    {
      'name': 'Organic Milk',
      'date': '2h ago',
      'time': '14:30',
      'calories': '150 kcal',
    },
    {
      'name': 'Whole Grain Bread',
      'date': '5h ago',
      'time': '11:15',
      'calories': '120 kcal',
    },
    {
      'name': 'Greek Yogurt',
      'date': '1d ago',
      'time': '09:45',
      'calories': '100 kcal',
    },
    {
      'name': 'Almond Butter',
      'date': '2d ago',
      'time': '16:20',
      'calories': '190 kcal',
    },
    {
      'name': 'Protein Bar',
      'date': '3d ago',
      'time': '12:00',
      'calories': '200 kcal',
    },
    {
      'name': 'Fresh Salmon',
      'date': '4d ago',
      'time': '18:30',
      'calories': '206 kcal',
    },
    {
      'name': 'Organic Apples',
      'date': '5d ago',
      'time': '10:15',
      'calories': '52 kcal',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Layout(
      showNav: true,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamed(context, '/home');
              }
            },
          ),
          title: Row(
            children: const [
              Icon(Icons.history, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'ALL HISTORY',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          centerTitle: false,
          automaticallyImplyLeading: false,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: historyItems.length,
          itemBuilder: (context, index) {
            final item = historyItems[index];
            final name = item['name']!.toLowerCase();
            Color bg = Colors.white;
            IconData icon = Icons.history;

            if (name.contains('milk')) {
              bg = const Color(0xFFE0F5F0);
              icon = Icons.local_drink;
            } else if (name.contains('bread') || name.contains('grain')) {
              bg = const Color(0xFFEDE9F3);
              icon = Icons.bakery_dining;
            } else if (name.contains('salmon') || name.contains('fish')) {
              bg = const Color(0xFFFFE8E8);
              icon = Icons.set_meal;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/results'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  item['date']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                                  child: CircleAvatar(
                                    radius: 3,
                                    backgroundColor: Colors.grey,
                                  ),
                                ),
                                Text(
                                  item['time']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                                  child: CircleAvatar(
                                    radius: 3,
                                    backgroundColor: Colors.grey,
                                  ),
                                ),
                                Text(
                                  item['calories']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
