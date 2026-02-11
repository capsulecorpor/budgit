import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => FinanceState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finances 2.0',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MainScaffold(),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class Partition {
  String id;
  String name;
  double balance;
  double monthlyAllocation;
  double goal;

  Partition({
    required this.id,
    required this.name,
    this.balance = 0,
    this.monthlyAllocation = 0,
    this.goal = 0,
  });
}

class Bucket {
  String id;
  String name;
  List<Partition> partitions;
  bool isLocked;

  Bucket({required this.id, required this.name, required this.partitions, this.isLocked = false});

  double get totalBalance => partitions.fold(0, (sum, item) => sum + item.balance);
  double get totalMonthlyAllocation => partitions.fold(0, (sum, item) => sum + item.monthlyAllocation);
}

class Transaction {
  String id;
  double amount;
  String comment;
  DateTime date;

  Transaction({required this.id, required this.amount, required this.comment, required this.date});
}

class ExpenseItem {
  String id;
  String name;
  double budget;
  bool isFixed;
  List<Transaction> transactions; // NEW: History of spending

  ExpenseItem({
    required this.id,
    required this.name,
    required this.budget,
    required this.isFixed,
    List<Transaction>? transactions,
  }) : transactions = transactions ?? [];

  // Dynamic getter for actual spent
  double get actual => transactions.fold(0, (sum, item) => sum + item.amount);
}

// ---------------------------------------------------------------------------
// STATE MANAGEMENT
// ---------------------------------------------------------------------------

class FinanceState extends ChangeNotifier {
  double monthlyIncome = 4960.00;
  double additionalIncome = 0.00;

  List<Bucket> buckets = [
    Bucket(id: 'b1', name: "Excess", isLocked: true, partitions: [
      Partition(id: 'p1', name: "Operating Capital", balance: 596.00),
    ]),
    Bucket(id: 'b2', name: "Large Purchases", partitions: [
      Partition(id: 'p2', name: "Travel", balance: 90, monthlyAllocation: 200, goal: 2000),
      Partition(id: 'p3', name: "Clothes", balance: 111, monthlyAllocation: 50, goal: 500),
      Partition(id: 'p4', name: "Car MX", balance: 15, monthlyAllocation: 150, goal: 1000),
    ]),
    Bucket(id: 'b3', name: "Savings", partitions: [
      Partition(id: 'p5', name: "Emergency Fund", balance: 5550, monthlyAllocation: 400, goal: 10000),
    ]),
    Bucket(id: 'b4', name: "Investments", partitions: [
      Partition(id: 'p6', name: "Roth IRA", balance: 10500, monthlyAllocation: 500),
    ]),
  ];

  List<ExpenseItem> fixedExpenses = [
    ExpenseItem(id: 'f1', name: "Rent", budget: 1200, isFixed: true, transactions: [
        Transaction(id: 't1', amount: 1200, comment: "Feb Rent", date: DateTime.now())
    ]),
    ExpenseItem(id: 'f2', name: "Car Insurance", budget: 175, isFixed: true, transactions: [
         Transaction(id: 't2', amount: 175, comment: "Geico", date: DateTime.now())
    ]),
    ExpenseItem(id: 'f3', name: "Phone Bill", budget: 82, isFixed: true),
    ExpenseItem(id: 'f4', name: "WiFi", budget: 38, isFixed: true),
  ];

  List<ExpenseItem> variableExpenses = [
    ExpenseItem(id: 'v1', name: "Groceries", budget: 400, isFixed: false, transactions: [
        Transaction(id: 't3', amount: 150, comment: "Costco run", date: DateTime.now().subtract(const Duration(days: 2))),
        Transaction(id: 't4', amount: 50, comment: "Trader Joes", date: DateTime.now()),
    ]),
    ExpenseItem(id: 'v2', name: "Dining Out", budget: 150, isFixed: false, transactions: [
        Transaction(id: 't5', amount: 155, comment: "Fancy Dinner", date: DateTime.now()),
    ]),
    ExpenseItem(id: 'v3', name: "Gas", budget: 100, isFixed: false),
    ExpenseItem(id: 'v4', name: "Electric", budget: 50, isFixed: false),
  ];

  // --- GETTERS ---
  double get totalIncome => monthlyIncome + additionalIncome;
  double get totalFixedCost => fixedExpenses.fold(0, (sum, item) => sum + item.budget);
  double get totalAllocations => buckets.where((b) => !b.isLocked).fold(0, (sum, b) => sum + b.totalMonthlyAllocation);
  double get totalVariableBudget => variableExpenses.fold(0, (sum, item) => sum + item.budget);
  double get totalVariableSpent => variableExpenses.fold(0, (sum, item) => sum + item.actual);
  double get totalSpentActual => totalFixedCost + totalAllocations + totalVariableSpent;
  double get projectedMonthEndExcess => totalIncome - (totalFixedCost + totalAllocations + totalVariableSpent);

  // --- ACTIONS ---

  void updateIncome(double newIncome) {
    monthlyIncome = newIncome;
    notifyListeners();
  }

  void addAdditionalIncome(double amount) {
    additionalIncome += amount;
    notifyListeners();
  }

  void createNewBucket(String name) {
    buckets.add(Bucket(id: DateTime.now().toString(), name: name, partitions: []));
    notifyListeners();
  }

  void addPartition(String bucketId, Partition part) {
    var bucket = buckets.firstWhere((b) => b.id == bucketId);
    bucket.partitions.add(part);
    notifyListeners();
  }

  void updatePartitionAllocation(String partitionId, double newAmount) {
    for (var bucket in buckets) {
      for (var part in bucket.partitions) {
        if (part.id == partitionId) {
          part.monthlyAllocation = newAmount;
          notifyListeners();
          return;
        }
      }
    }
  }

  void addFixedExpense(String name, double amount) {
    fixedExpenses.add(ExpenseItem(
      id: DateTime.now().toString(),
      name: name,
      budget: amount,
      isFixed: true
    ));
    notifyListeners();
  }

  void editFixedExpense(String id, String newName, double newAmount) {
    var item = fixedExpenses.firstWhere((e) => e.id == id);
    item.name = newName;
    item.budget = newAmount;
    notifyListeners();
  }

  void addVariableExpenseRow(String name, double budget) {
    variableExpenses.add(ExpenseItem(
      id: DateTime.now().toString(),
      name: name,
      budget: budget,
      isFixed: false
    ));
    notifyListeners();
  }

  // FIXED: Now properly updates the budget limit
  void editVariableBudget(String id, String newName, double newBudget) {
    var item = variableExpenses.firstWhere((e) => e.id == id);
    item.name = newName;
    item.budget = newBudget;
    notifyListeners();
  }

  // UPDATED: Now adds a Transaction object instead of just a double
  void addVariableTransaction(String id, double amount, String comment) {
    var item = variableExpenses.firstWhere((e) => e.id == id);
    item.transactions.add(Transaction(
      id: DateTime.now().toString(),
      amount: amount,
      comment: comment,
      date: DateTime.now()
    ));
    // Since 'actual' is a getter that sums transactions, we just notify
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// UI FRAMEWORK
// ---------------------------------------------------------------------------

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const DashboardScreen(),
    const AllocationsScreen(),
    const BudgetScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finances 2.0"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showIncomeSettings(context),
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), label: 'Allocations'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Budget'),
        ],
      ),
    );
  }

  void _showIncomeSettings(BuildContext context) {
    final state = Provider.of<FinanceState>(context, listen: false);
    final controller = TextEditingController(text: state.monthlyIncome.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Income Settings"),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Expected Monthly Income")),
        actions: [
          ElevatedButton(
            onPressed: () { state.updateIncome(double.tryParse(controller.text) ?? 0); Navigator.pop(ctx); },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 1: DASHBOARD
// ---------------------------------------------------------------------------
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    final currency = NumberFormat.simpleCurrency();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Spending Pulse", style: Theme.of(context).textTheme.titleLarge),
                      Text("${currency.format(state.totalSpentActual)} / ${currency.format(state.totalIncome)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20, child: SpendingBarGraph()),
                   const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Projected Month End:", style: TextStyle(color: Colors.grey[600])),
                      Text(currency.format(state.projectedMonthEndExcess), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: state.projectedMonthEndExcess >= 0 ? Colors.green : Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text("Where is my Money?", style: Theme.of(context).textTheme.headlineSmall),
          ...state.buckets.map((bucket) => Card(
            child: ListTile(
              title: Text(bucket.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(bucket.name == "Excess" ? "Available Operating Capital" : "${bucket.partitions.length} partitions"),
              trailing: Text(currency.format(bucket.totalBalance), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )),
        ],
      ),
    );
  }
}

class SpendingBarGraph extends StatelessWidget {
  const SpendingBarGraph({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    if (state.totalIncome == 0) return const SizedBox();
    double maxScale = state.totalIncome; 
    if (state.totalSpentActual > maxScale) maxScale = state.totalSpentActual;

    double fixedPct = (state.totalFixedCost / maxScale).clamp(0.0, 1.0);
    double allocPct = (state.totalAllocations / maxScale).clamp(0.0, 1.0);
    double varPct = (state.totalVariableSpent / maxScale).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Expanded(flex: (fixedPct * 1000).toInt(), child: Container(color: Colors.blue[300])),
          Expanded(flex: (allocPct * 1000).toInt(), child: Container(color: Colors.purple[300])),
          Expanded(flex: (varPct * 1000).toInt(), child: Container(color: state.totalVariableSpent > state.totalVariableBudget ? Colors.red[300] : Colors.green[300])),
          Expanded(flex: ((1 - fixedPct - allocPct - varPct) * 1000).toInt().clamp(0, 1000), child: Container(color: Colors.grey[300])),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 2: ALLOCATIONS
// ---------------------------------------------------------------------------
class AllocationsScreen extends StatelessWidget {
  const AllocationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    final currency = NumberFormat.simpleCurrency();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // Add bucket logic omitted for brevity
        label: const Text("New Bucket"),
        icon: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.buckets.length,
        itemBuilder: (context, index) {
          final bucket = state.buckets[index];
          return Card(
            child: ExpansionTile(
              title: Text(bucket.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Total: ${currency.format(bucket.totalBalance)}"),
              children: [
                ...bucket.partitions.map((part) => ListTile(
                  title: Text(part.name),
                  subtitle: Text("Monthly Deposit: ${currency.format(part.monthlyAllocation)}"),
                  trailing: Text(currency.format(part.balance)),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 3: BUDGET
// ---------------------------------------------------------------------------
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    final currency = NumberFormat.simpleCurrency();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Monthly Income", style: TextStyle(color: Colors.grey[600])),
                Text(currency.format(state.monthlyIncome), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              if (state.additionalIncome > 0) Text("+ ${currency.format(state.additionalIncome)} extra", style: const TextStyle(color: Colors.green)),
            ],
          ),
          const Divider(height: 30),

          // Fixed
          _SectionHeader(title: "Fixed Spending", total: state.totalFixedCost, onAdd: () => _showAddFixedDialog(context)),
          ...state.fixedExpenses.map((e) => ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle_outline, color: Colors.blueGrey),
            title: Text(e.name),
            trailing: Text(currency.format(e.budget)),
          )),
          const SizedBox(height: 20),

          // Allocations
          _SectionHeader(title: "Allocations", total: state.totalAllocations, onAdd: null),
          ...state.buckets.where((b) => !b.isLocked).expand((b) => b.partitions).map((p) => ListTile(
            dense: true,
            leading: const Icon(Icons.arrow_forward, color: Colors.purple),
            title: Text("To ${p.name}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(currency.format(p.monthlyAllocation)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  onPressed: () => _showEditAllocationDialog(context, p),
                )
              ],
            ),
          )),
          const SizedBox(height: 20),

          // Variable
          _SectionHeader(title: "Variable Spending", total: state.totalVariableBudget, onAdd: () => _showAddVariableRowDialog(context)),
          ...state.variableExpenses.map((e) {
            double percent = (e.actual / e.budget).clamp(0.0, 1.0);
            bool isOver = e.actual > e.budget;
            
            return InkWell(
              // NEW: Tap to view History
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryScreen(item: e))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ]),
                        Row(
                          children: [
                             Text("${currency.format(e.actual)} / ${currency.format(e.budget)}", style: TextStyle(color: isOver ? Colors.red : Colors.black, fontWeight: isOver ? FontWeight.bold : FontWeight.normal)),
                            // NEW: Edit Budget Button
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                              onPressed: () => _showEditVariableRowDialog(context, e),
                            ),
                            // NEW: Quick Add Button
                            IconButton(
                              icon: const Icon(Icons.add_circle, size: 20, color: Colors.blueGrey),
                              onPressed: () => _showAddTransactionDialog(context, e),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: percent, backgroundColor: Colors.grey[200], color: isOver ? Colors.red : Colors.green, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- DIALOGS ---
  void _showAddFixedDialog(BuildContext context) { /* Omitted for brevity, same as previous */ }
  
  void _showEditAllocationDialog(BuildContext context, Partition part) {
    final amtCtrl = TextEditingController(text: part.monthlyAllocation.toString());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("Edit Allocation: ${part.name}"),
      content: TextField(controller: amtCtrl, keyboardType: TextInputType.number),
      actions: [
        ElevatedButton(onPressed: () {
          Provider.of<FinanceState>(context, listen: false).updatePartitionAllocation(part.id, double.tryParse(amtCtrl.text) ?? 0);
          Navigator.pop(ctx);
        }, child: const Text("Save"))
      ],
    ));
  }

  void _showAddVariableRowDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Add Budget Category"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
        TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: "Monthly Limit"), keyboardType: TextInputType.number),
      ]),
      actions: [
        ElevatedButton(onPressed: () {
          Provider.of<FinanceState>(context, listen: false).addVariableExpenseRow(nameCtrl.text, double.tryParse(amtCtrl.text) ?? 0);
          Navigator.pop(ctx);
        }, child: const Text("Add"))
      ],
    ));
  }

  // NEW: Dialog to edit the budget limit
  void _showEditVariableRowDialog(BuildContext context, ExpenseItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final amtCtrl = TextEditingController(text: item.budget.toString());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Edit Category Budget"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
        TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: "New Monthly Limit"), keyboardType: TextInputType.number),
      ]),
      actions: [
        ElevatedButton(onPressed: () {
          Provider.of<FinanceState>(context, listen: false).editVariableBudget(item.id, nameCtrl.text, double.tryParse(amtCtrl.text) ?? 0);
          Navigator.pop(ctx);
        }, child: const Text("Save"))
      ],
    ));
  }

  // NEW: Dialog with Comment field
  void _showAddTransactionDialog(BuildContext context, ExpenseItem item) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add to ${item.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amtCtrl, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount", prefixText: "\$")),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "What was it? (Comment)")),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Provider.of<FinanceState>(context, listen: false).addVariableTransaction(item.id, double.tryParse(amtCtrl.text) ?? 0, noteCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double total;
  final VoidCallback? onAdd;
  const _SectionHeader({required this.title, required this.total, required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), if (onAdd != null) IconButton(icon: const Icon(Icons.add_circle, color: Colors.blueGrey), onPressed: onAdd)]),
        Text(NumberFormat.simpleCurrency().format(total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// NEW SCREEN: TRANSACTION HISTORY
// ---------------------------------------------------------------------------
class TransactionHistoryScreen extends StatelessWidget {
  final ExpenseItem item;
  const TransactionHistoryScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // We don't need a watcher here necessarily if we passed the object, 
    // but to get live updates if we added a delete feature, we'd want to find the item in the state.
    // For now, simple display:
    
    return Scaffold(
      appBar: AppBar(title: Text("${item.name} History")),
      body: ListView.separated(
        itemCount: item.transactions.length,
        separatorBuilder: (c, i) => const Divider(),
        itemBuilder: (context, index) {
          // Show newest first
          final tx = item.transactions[item.transactions.length - 1 - index];
          return ListTile(
            title: Text(tx.comment.isEmpty ? "Expense" : tx.comment),
            subtitle: Text(DateFormat.yMMMd().format(tx.date)),
            trailing: Text(NumberFormat.simpleCurrency().format(tx.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          );
        },
      ),
    );
  }
}