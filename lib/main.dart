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
// DATA MODELS & STATE MANAGEMENT
// ---------------------------------------------------------------------------

class Partition {
  String name;
  double balance;
  double monthlyAllocation; // How much we WANT to put in every month
  double goal;

  Partition({
    required this.name,
    this.balance = 0,
    this.monthlyAllocation = 0,
    this.goal = 0,
  });
}

class Bucket {
  String name;
  List<Partition> partitions;
  bool isLocked; // For "Excess" bucket which can't have custom partitions added

  Bucket({required this.name, required this.partitions, this.isLocked = false});

  double get totalBalance => partitions.fold(0, (sum, item) => sum + item.balance);
  double get totalMonthlyAllocation => partitions.fold(0, (sum, item) => sum + item.monthlyAllocation);
}

class ExpenseItem {
  String name;
  double budget;
  double actual;
  bool isFixed;

  ExpenseItem({
    required this.name,
    required this.budget,
    this.actual = 0,
    required this.isFixed,
  });
}

class FinanceState extends ChangeNotifier {
  // Global Settings
  double monthlyIncome = 4960.00;
  double additionalIncome = 0.00;

  // Buckets (The "Where is my money" section)
  List<Bucket> buckets = [
    Bucket(name: "Excess", isLocked: true, partitions: [
      Partition(name: "Operating Capital", balance: 596.00),
    ]),
    Bucket(name: "Large Purchases", partitions: [
      Partition(name: "Travel", balance: 90, monthlyAllocation: 200, goal: 2000),
      Partition(name: "Clothes", balance: 111, monthlyAllocation: 50, goal: 500),
      Partition(name: "Car MX", balance: 15, monthlyAllocation: 150, goal: 1000),
    ]),
    Bucket(name: "Savings", partitions: [
      Partition(name: "Emergency Fund", balance: 5550, monthlyAllocation: 400, goal: 10000),
    ]),
    Bucket(name: "Investments", partitions: [
      Partition(name: "Roth IRA", balance: 10500, monthlyAllocation: 500),
    ]),
  ];

  // Budget Items (The "Plan")
  List<ExpenseItem> fixedExpenses = [
    ExpenseItem(name: "Rent", budget: 1200, actual: 1200, isFixed: true),
    ExpenseItem(name: "Car Insurance", budget: 175, actual: 175, isFixed: true),
    ExpenseItem(name: "Phone Bill", budget: 82, actual: 82, isFixed: true),
    ExpenseItem(name: "WiFi", budget: 38, actual: 38, isFixed: true),
  ];

  List<ExpenseItem> variableExpenses = [
    ExpenseItem(name: "Groceries", budget: 400, actual: 200, isFixed: false),
    ExpenseItem(name: "Dining Out", budget: 150, actual: 155, isFixed: false), // Overspent example
    ExpenseItem(name: "Gas", budget: 100, actual: 40, isFixed: false),
    ExpenseItem(name: "Electric", budget: 50, actual: 43, isFixed: false),
  ];

  // --- CALCULATED GETTERS ---

  double get totalIncome => monthlyIncome + additionalIncome;

  double get totalFixedCost => fixedExpenses.fold(0, (sum, item) => sum + item.budget);
  
  // Sum of all monthly allocations defined in buckets (excluding Excess bucket)
  double get totalAllocations => buckets
      .where((b) => b.name != "Excess")
      .fold(0, (sum, b) => sum + b.totalMonthlyAllocation);

  double get totalVariableBudget => variableExpenses.fold(0, (sum, item) => sum + item.budget);
  double get totalVariableSpent => variableExpenses.fold(0, (sum, item) => sum + item.actual);

  // The projected math for the end of the month
  double get projectedMonthEndExcess {
    return totalIncome - (totalFixedCost + totalAllocations + totalVariableSpent);
  }

  // --- ACTIONS ---

  void updateIncome(double newIncome) {
    monthlyIncome = newIncome;
    notifyListeners();
  }

  void addAdditionalIncome(double amount) {
    additionalIncome += amount;
    notifyListeners();
  }

  void addPartition(String bucketName, Partition part) {
    var bucket = buckets.firstWhere((b) => b.name == bucketName);
    bucket.partitions.add(part);
    notifyListeners();
  }

  void addVariableTransaction(String categoryName, double amount) {
    var item = variableExpenses.firstWhere((e) => e.name == categoryName);
    item.actual += amount;
    notifyListeners();
  }

  void createNewBucket(String name) {
    buckets.add(Bucket(name: name, partitions: []));
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
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Allocations',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
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
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Expected Monthly Income"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              state.updateIncome(double.tryParse(controller.text) ?? 0);
              Navigator.pop(ctx);
            },
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
          // 1. Header Card (Spending Pulse)
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Spending Pulse", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  const SizedBox(height: 20, child: SpendingBarGraph()),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Projected Month End:", style: TextStyle(color: Colors.grey[600])),
                      Text(
                        currency.format(state.projectedMonthEndExcess),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: state.projectedMonthEndExcess >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          
          // 2. Where is my Money?
          Text("Where is my Money?", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          
          ...state.buckets.map((bucket) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(bucket.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  bucket.name == "Excess" ? "Available Operating Capital" : "${bucket.partitions.length} partitions",
                ),
                trailing: Text(
                  currency.format(bucket.totalBalance),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                   // In a real app, this would switch tabs or nav stack
                   // For this prototype, user clicks the Allocations tab manually
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Custom Painter or Row for the "Bullet Chart" style graph
class SpendingBarGraph extends StatelessWidget {
  const SpendingBarGraph({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    
    // Calculate percentages relative to Total Income
    double income = state.totalIncome;
    if (income == 0) return const SizedBox();

    double fixedPct = (state.totalFixedCost / income).clamp(0.0, 1.0);
    double allocPct = (state.totalAllocations / income).clamp(0.0, 1.0);
    double varPct = (state.totalVariableSpent / income).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Expanded(flex: (fixedPct * 100).toInt(), child: Container(color: Colors.blue[300])),
          Expanded(flex: (allocPct * 100).toInt(), child: Container(color: Colors.purple[300])),
          Expanded(flex: (varPct * 100).toInt(), child: Container(color: state.totalVariableSpent > state.totalVariableBudget ? Colors.red[300] : Colors.green[300])),
          Expanded(flex: ((1 - fixedPct - allocPct - varPct) * 100).toInt().clamp(0, 100), child: Container(color: Colors.grey[300])),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 2: ALLOCATIONS (Buckets)
// ---------------------------------------------------------------------------

class AllocationsScreen extends StatelessWidget {
  const AllocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FinanceState>();
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBucketDialog(context),
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
                  onTap: () => _showPartitionDetails(context, part),
                )),
                if (!bucket.isLocked)
                  TextButton.icon(
                    onPressed: () => _showAddPartitionDialog(context, bucket.name),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Add Partition"),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddBucketDialog(BuildContext context) {
    // Boilerplate dialog to add string to state.createNewBucket
  }

  void _showAddPartitionDialog(BuildContext context, String bucketName) {
     final nameController = TextEditingController();
     final allocController = TextEditingController();
     
     showDialog(context: context, builder: (ctx) => AlertDialog(
       title: Text("Add Partition to $bucketName"),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
           TextField(controller: allocController, decoration: const InputDecoration(labelText: "Monthly Deposit"), keyboardType: TextInputType.number),
         ],
       ),
       actions: [
         ElevatedButton(
           onPressed: () {
             Provider.of<FinanceState>(context, listen: false).addPartition(
               bucketName, 
               Partition(
                 name: nameController.text, 
                 monthlyAllocation: double.tryParse(allocController.text) ?? 0
               )
             );
             Navigator.pop(ctx);
           },
           child: const Text("Add"),
         )
       ],
     ));
  }

  void _showPartitionDetails(BuildContext context, Partition part) {
    // Show details bottom sheet
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Monthly Income", style: TextStyle(color: Colors.grey[600])),
                  Text(currency.format(state.monthlyIncome), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (state.additionalIncome > 0)
                    Text("+ ${currency.format(state.additionalIncome)} extra", style: const TextStyle(color: Colors.green)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddIncomeDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Extra"),
              )
            ],
          ),
          const Divider(height: 30),

          // 1. Fixed Spending
          _SectionHeader(title: "Fixed Spending", total: state.totalFixedCost),
          ...state.fixedExpenses.map((e) => ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle_outline, color: Colors.blueGrey),
            title: Text(e.name),
            trailing: Text(currency.format(e.budget)),
          )),
          const SizedBox(height: 20),

          // 2. Allocations
          _SectionHeader(title: "Allocations (To Buckets)", total: state.totalAllocations),
          ...state.buckets.where((b) => b.name != "Excess").expand((b) => b.partitions).map((p) {
             if (p.monthlyAllocation == 0) return const SizedBox.shrink();
             return ListTile(
              dense: true,
              leading: const Icon(Icons.arrow_forward, color: Colors.purple),
              title: Text("To ${p.name}"),
              trailing: Text(currency.format(p.monthlyAllocation)),
             );
          }),
          const SizedBox(height: 20),

          // 3. Variable Spending
          _SectionHeader(title: "Variable Spending", total: state.totalVariableBudget),
          ...state.variableExpenses.map((e) {
            double percent = (e.actual / e.budget).clamp(0.0, 1.0);
            bool isOver = e.actual > e.budget;
            
            return InkWell(
              onTap: () => _showAddTransactionDialog(context, e),
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
                        Text(
                          "${currency.format(e.actual)} / ${currency.format(e.budget)}",
                          style: TextStyle(
                            color: isOver ? Colors.red : Colors.black,
                            fontWeight: isOver ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey[200],
                      color: isOver ? Colors.red : Colors.green,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddIncomeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("One-Time Extra Income"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount"),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Provider.of<FinanceState>(context, listen: false).addAdditionalIncome(double.tryParse(controller.text) ?? 0);
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, ExpenseItem item) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add to ${item.name}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Amount Spent",
            prefixText: "\$",
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Provider.of<FinanceState>(context, listen: false).addVariableTransaction(item.name, double.tryParse(controller.text) ?? 0);
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
  
  const _SectionHeader({required this.title, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(NumberFormat.simpleCurrency().format(total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }
}