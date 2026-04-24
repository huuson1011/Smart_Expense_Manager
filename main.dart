import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/transaction_provider.dart';
import 'models/transaction.dart';
import 'widgets/transaction_list.dart';
import 'screens/statistic_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void showTransactionForm(BuildContext context, [Transaction? existingTx]) {
    final isEditing = existingTx != null;
    final titleCtrl = TextEditingController(text: isEditing ? existingTx.title : "");
    final amountCtrl = TextEditingController(text: isEditing ? existingTx.amount.toStringAsFixed(0) : "");
    final otherCtrl = TextEditingController();

    final List<String> availableCategories = ['Ăn uống', 'Di chuyển', 'Mua sắm'];

    String category = 'Ăn uống';
    if (isEditing) {
      category = availableCategories.contains(existingTx.category) ? existingTx.category : 'Khác';
      if (category == 'Khác') otherCtrl.text = existingTx.category;
    }

    bool isOther = category == 'Khác';
    String wallet = isEditing ? existingTx.walletName : 'Tiền mặt';
    TransactionType type = isEditing ? existingTx.type : TransactionType.expense;
    DateTime date = isEditing ? existingTx.date : DateTime.now();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(isEditing ? "Sửa giao dịch" : "Thêm giao dịch", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 10),
            Text(DateFormat('dd/MM/yyyy').format(date)),
            const Spacer(),
            TextButton(onPressed: () async {
              final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2022), lastDate: DateTime.now());
              if (d != null) setModalState(() => date = d);
            }, child: const Text("Chọn ngày"))
          ]),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Tên giao dịch")),
          TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Số tiền"), keyboardType: TextInputType.number),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            DropdownButton<String>(
                value: category,
                items: [...availableCategories, 'Khác'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setModalState(() { category = v!; isOther = v == 'Khác'; })),
            DropdownButton<TransactionType>(value: type, items: const [DropdownMenuItem(value: TransactionType.expense, child: Text("Chi")), DropdownMenuItem(value: TransactionType.income, child: Text("Thu"))],
                onChanged: (v) => setModalState(() => type = v!)),
          ]),
          Row(children: [ const Text("Nguồn: "), DropdownButton<String>(value: wallet, items: ['Tiền mặt', 'ATM'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setModalState(() => wallet = v!))]),
          if (isOther) TextField(controller: otherCtrl, decoration: const InputDecoration(labelText: "Tên danh mục tự nhập")),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isEditing ? Colors.orange : Colors.blue, foregroundColor: Colors.white),
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text) ?? 0;
                if (titleCtrl.text.isEmpty || amt <= 0) return;
                final tx = Transaction(id: isEditing ? existingTx.id : null, title: titleCtrl.text, amount: amt, date: date, category: isOther ? otherCtrl.text : category, walletName: wallet, type: type);
                isEditing ? Provider.of<TransactionProvider>(context, listen: false).updateTransaction(existingTx.id, tx) : Provider.of<TransactionProvider>(context, listen: false).addTransaction(tx);
                Navigator.pop(context);
              }, child: Text(isEditing ? "CẬP NHẬT" : "LƯU"))),
          const SizedBox(height: 20),
        ])),
      )),
    );
  }

  void showEditForm(BuildContext context, Transaction tx) => showTransactionForm(context, tx);

  void _showEditBudgetDialog(BuildContext context, Budget budget, TransactionProvider provider) {
    final ctrl = TextEditingController(text: budget.limit.toStringAsFixed(0));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("Ngân sách ${budget.category}"),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Hạn mức (VNĐ)")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () {
              final l = double.tryParse(ctrl.text) ?? 0;
              if (l > 0) provider.updateBudgetLimit(budget.category, l);
              Navigator.pop(ctx);
            }, child: const Text("Lưu"))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final warnings = provider.budgetWarnings;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Lý Tài Chính"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticScreen())),
          ),
        ],
      ),
      body: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(20), margin: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(15)),
            child: Column(children: [
              const Text("TỔNG SỐ DƯ", style: TextStyle(color: Colors.white70)),
              Text(fmt.format(provider.totalBalance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ])),

        // HIỂN THỊ CẢNH BÁO NẾU CÓ
        if (warnings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: warnings.map((msg) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: msg.contains("đã vượt") ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: msg.contains("đã vượt") ? Colors.red : Colors.orange),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded, color: msg.contains("đã vượt") ? Colors.red : Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(child: Text(msg, style: TextStyle(color: msg.contains("đã vượt") ? Colors.red.shade900 : Colors.orange.shade900, fontWeight: FontWeight.bold))),
                ]),
              )).toList(),
            ),
          ),

        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("NGÂN SÁCH", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          ...provider.budgets.values.map((b) {
            double p = b.spent / b.limit;
            Color c = p >= 1.0 ? Colors.red : (p >= 0.8 ? Colors.orange : Colors.green);
            return Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                GestureDetector(onTap: () => _showEditBudgetDialog(context, b, provider), child: Row(children: [Text(b.category), const Icon(Icons.edit, size: 14, color: Colors.blue)])),
                Text("${fmt.format(b.spent)} / ${fmt.format(b.limit)}", style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(value: p > 1 ? 1 : p, color: c, backgroundColor: Colors.grey.shade300, minHeight: 8),
              ),
              const SizedBox(height: 12),
            ]);
          }).toList(),
        ])),
        const Divider(),
        Expanded(child: TransactionList()),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => showTransactionForm(context), child: const Icon(Icons.add)),
    );
  }
}