import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <({String title, IconData icon, String? route})>[
      (title: 'משימות', icon: Icons.checklist_rounded, route: '/tasks'),
      (title: 'ארגזים', icon: Icons.inventory_2_outlined, route: null),
      (title: 'חדרים', icon: Icons.meeting_room_outlined, route: null),
      (title: 'מכירה', icon: Icons.sell_outlined, route: null),
      (title: 'קניות', icon: Icons.shopping_cart_outlined, route: null),
      (title: 'תקציב', icon: Icons.account_balance_wallet_outlined, route: null),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MoveMate'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('בוקר טוב 👋', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('נותרו 18 ימים למעבר'),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('התקדמות כללית', style: Theme.of(context).textTheme.titleMedium), const Text('38%')]),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(value: .38, minHeight: 10, borderRadius: BorderRadius.all(Radius.circular(20))),
                  const SizedBox(height: 10),
                  const Text('עוד צעד אחד לבית החדש!'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 136,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.75,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                StatCard(icon: Icons.check_circle_outline, value: '12/28', label: 'משימות'),
                StatCard(icon: Icons.inventory_2_outlined, value: '8/30', label: 'ארגזים'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('גישה מהירה', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemBuilder: (context, index) {
              final action = actions[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: action.route == null ? null : () => context.push(action.route!),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(action.icon, size: 30), const SizedBox(height: 8), Text(action.title)]),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('הוספה מהירה')),
    );
  }
}
