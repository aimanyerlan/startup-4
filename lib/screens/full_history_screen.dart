import 'package:flutter/material.dart';
import 'package:my_app/widgets/layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Не забудьте добавить intl в pubspec.yaml

class FullHistoryScreen extends StatelessWidget {
  const FullHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Получаем ID текущего пользователя
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Layout(
      showNav: true,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: const [
              Icon(Icons.history, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'ИСТОРИЯ СКАНОВ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        body: uid == null 
          ? const Center(child: Text("Войдите в аккаунт, чтобы увидеть историю"))
          : StreamBuilder<QuerySnapshot>(
              // Подключаемся к коллекции сохраненных сканов пользователя
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('saved_scans')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Ошибка: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("История пуста"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    // Форматируем дату из Timestamp
                    String formattedDate = "Недавно";
                    if (data['timestamp'] != null) {
                      DateTime date = (data['timestamp'] as Timestamp).toDate();
                      formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);
                    }

                    final bool isSafe = data['status']?.toString().toUpperCase() == 'SAFE';
                    final String name = data['productName'] ?? 'Продукт';
                    final String calories = data['calories'] ?? '-- ккал';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        // Передаем данные конкретного скана на экран результатов
                        onTap: () => Navigator.pushNamed(
                          context, 
                          '/results', 
                          arguments: data // Передаем все данные документа
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isSafe ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              width: 2
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSafe ? Colors.green[50] : Colors.red[50],
                                child: Icon(
                                  isSafe ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                  color: isSafe ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        const SizedBox(width: 10),
                                        Text(calories, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      ),
    );
  }
}