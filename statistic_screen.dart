import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class StatisticScreen extends StatelessWidget {
  const StatisticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Thống Kê Tài Chính"),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: "CHI TIÊU", icon: Icon(Icons.upload_rounded)),
              Tab(text: "THU NHẬP", icon: Icon(Icons.download_rounded)),
            ],
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const TabBarView(
          children: [
            ChartPageView(type: TransactionType.expense),
            ChartPageView(type: TransactionType.income),
          ],
        ),
      ),
    );
  }
}

class ChartPageView extends StatelessWidget {
  final TransactionType type;
  const ChartPageView({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final data = type == TransactionType.expense
        ? provider.expenseByCategory
        : provider.incomeByCategory;

    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.amber
    ];

    final double total = data.values.fold(0, (sum, item) => sum + item);

    if (data.isEmpty) {
      return Center(
        child: Text(
          "Chưa có dữ liệu ${type == TransactionType.expense ? 'chi' : 'thu'}.",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          type == TransactionType.expense ? "CƠ CẤU CHI TIÊU" : "NGUỒN THU NHẬP",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.entries.toList().asMap().entries.map((entry) {
                int i = entry.key;
                var val = entry.value;
                final percentage = (val.value / total) * 100;
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: val.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text(
          "Tổng ${type == TransactionType.expense ? 'chi' : 'thu'}: ${fmt.format(total)}",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: type == TransactionType.expense ? Colors.red : Colors.green
          ),
        ),
        const SizedBox(height: 10),
        const Divider(),

        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              String category = data.keys.elementAt(i);
              double amount = data.values.elementAt(i);
              double percentage = (amount / total) * 100;

              return ListTile(
                leading: CircleAvatar(backgroundColor: colors[i % colors.length], radius: 8),
                title: Text(category, style: const TextStyle(fontSize: 14)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        fmt.format(amount),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: type == TransactionType.expense ? Colors.redAccent : Colors.green
                        )
                    ),
                    Text("${percentage.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }
}