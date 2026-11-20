import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const brand = Color(0xFF173B5E);
const accent = Color(0xFF1C8C70);
const flyName = 'Bombay Fly (চরকি)';
const defaultProducts = <String>[
  'Popular Bus', 'Tourist Bus', 'Speed Train', 'High Speed Train',
  '3D LED Car', 'Fiction LED Car', 'Police Car', 'Kids Tools Set',
  'Billing Car', 'Express Train', '3 Pcs Baby Bus', 'RAB Super Bus',
  'Fiction Plane', 'Drill Machine Set', 'Tools Set', 'RAB Bus',
  'Revolver Gun', 'Bombay Fight', 'Sniper Gun', 'Police Jeep', flyName,
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FactoryDb.instance.init();
  runApp(const WonderFactoryApp());
}

class Production {
  final int? id;
  final String date;
  final String product;
  final int cartons;
  const Production({this.id, required this.date, required this.product, required this.cartons});
  Map<String, Object?> toMap() => {'id': id, 'date': date, 'product': product, 'cartons': cartons};
  factory Production.fromMap(Map<String, Object?> m) => Production(
    id: m['id'] as int, date: m['date'] as String,
    product: m['product'] as String, cartons: m['cartons'] as int,
  );
}

class FactoryDb {
  FactoryDb._();
  static final instance = FactoryDb._();
  Database? _db;
  Future<void> init() async {
    final path = p.join(await getDatabasesPath(), 'wonder_factory.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''CREATE TABLE production(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        product TEXT NOT NULL,
        cartons INTEGER NOT NULL CHECK(cartons > 0)
      )''');
      await db.execute('''CREATE TABLE products(name TEXT PRIMARY KEY)''');
      final batch = db.batch();
      for (final name in defaultProducts) { batch.insert('products', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore); }
      await batch.commit(noResult: true);
    });
  }
  Database get db => _db!;
  Future<List<Production>> records() async => (await db.query('production', orderBy: 'date DESC, id DESC')).map(Production.fromMap).toList();
  Future<void> add(Production r) async { await db.insert('production', r.toMap()); }
  Future<void> update(Production r) async { await db.update('production', r.toMap(), where: 'id=?', whereArgs: [r.id]); }
  Future<void> delete(int id) async { await db.delete('production', where: 'id=?', whereArgs: [id]); }
  Future<List<String>> products() async => (await db.query('products', orderBy: 'name')).map((e) => e['name'] as String).toList();
  Future<void> addProduct(String name) async { await db.insert('products', {'name': name.trim()}, conflictAlgorithm: ConflictAlgorithm.ignore); }
  Future<void> deleteProduct(String name) async { await db.delete('products', where: 'name=?', whereArgs: [name]); }
}

class WonderFactoryApp extends StatelessWidget {
  const WonderFactoryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Wonder Factory Management',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: brand), scaffoldBackgroundColor: const Color(0xFFF4F7FA), useMaterial3: true, appBarTheme: const AppBarTheme(backgroundColor: brand, foregroundColor: Colors.white, centerTitle: false)),
    home: const MainShell(),
  );
}

class MainShell extends StatefulWidget { const MainShell({super.key}); @override State<MainShell> createState() => _MainShellState(); }
class _MainShellState extends State<MainShell> {
  int tab = 0;
  int refresh = 0;
  void changed() => setState(() => refresh++);
  @override
  Widget build(BuildContext context) {
    final pages = [DashboardPage(key: ValueKey('d$refresh'), onAdd: () => setState(() => tab = 1)), AddPage(onSaved: changed), HistoryPage(key: ValueKey('h$refresh'), onChanged: changed), ReportsPage(key: ValueKey('r$refresh')), ProductsPage(key: ValueKey('p$refresh'), onChanged: changed)];
    return Scaffold(
      appBar: AppBar(title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Wonder Factory', style: TextStyle(fontWeight: FontWeight.bold)), Text('Management', style: TextStyle(fontSize: 12, color: Colors.white70))]), actions: [IconButton(onPressed: () => showAboutDialog(context: context, applicationName: 'Wonder Factory Management', applicationVersion: '1.0.0'), icon: const Icon(Icons.info_outline))]),
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'হোম'), NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'এন্ট্রি'), NavigationDestination(icon: Icon(Icons.history), label: 'ইতিহাস'), NavigationDestination(icon: Icon(Icons.bar_chart), label: 'রিপোর্ট'), NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'পণ্য')]),
    );
  }
}

Future<List<Production>> loadRecords() => FactoryDb.instance.records();
String fmtDate(String iso) { try { return DateFormat('dd-MM-yyyy').format(DateTime.parse(iso)); } catch (_) { return iso; } }
int mainTotal(Iterable<Production> rows) => rows.where((r) => r.product != flyName).fold(0, (s, r) => s + r.cartons);
int flyTotal(Iterable<Production> rows) => rows.where((r) => r.product == flyName).fold(0, (s, r) => s + r.cartons);

class DashboardPage extends StatelessWidget {
  final VoidCallback onAdd;
  const DashboardPage({super.key, required this.onAdd});
  @override Widget build(BuildContext context) => FutureBuilder<List<Production>>(future: loadRecords(), builder: (context, snap) {
    final rows = snap.data ?? [];
    final now = DateTime.now(); final month = DateFormat('yyyy-MM').format(now);
    final thisMonth = rows.where((r) => r.date.startsWith(month)).toList();
    return RefreshIndicator(onRefresh: () async { (context as Element).markNeedsBuild(); }, child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [brand, Color(0xFF28648F)]), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('কারখানার উৎপাদন ব্যবস্থাপনা', style: TextStyle(color: Colors.white70)), const SizedBox(height: 8), const Text('আজকের হিসাব সহজে রাখুন', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 16), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: brand), onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('নতুন উৎপাদন যোগ করুন'))])),
      const SizedBox(height: 18), const Text('সারসংক্ষেপ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
      Row(children: [Expanded(child: StatCard(title: 'এই মাসে মোট', value: '${mainTotal(thisMonth)}', unit: 'কার্টন', icon: Icons.inventory, color: accent)), const SizedBox(width: 10), Expanded(child: StatCard(title: 'মোট এন্ট্রি', value: '${thisMonth.length}', unit: 'টি রেকর্ড', icon: Icons.receipt_long, color: const Color(0xFF7255A5)))]),
      const SizedBox(height: 10), Row(children: [Expanded(child: StatCard(title: 'চরকি আলাদা', value: '${flyTotal(thisMonth)}', unit: 'কার্টন', icon: Icons.toys_outlined, color: const Color(0xFFB56A2A))), const SizedBox(width: 10), Expanded(child: StatCard(title: 'সব মাসে মোট', value: '${mainTotal(rows)}', unit: 'কার্টন', icon: Icons.summarize, color: const Color(0xFF3476A8)))]),
      const SizedBox(height: 20), const Text('সাম্প্রতিক উৎপাদন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      if (rows.isEmpty) const EmptyState(text: 'এখনো কোনো উৎপাদন এন্ট্রি নেই। নতুন উৎপাদন যোগ করুন।') else ...rows.take(5).map((r) => RecordTile(record: r)),
      const SizedBox(height: 12), const Text('নোট: Bombay Fly (চরকি)-এর কার্টন মূল উৎপাদনের মোট হিসাবের বাইরে আলাদাভাবে দেখানো হয়.', style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]));
  });
}

class StatCard extends StatelessWidget { final String title, value, unit; final IconData icon; final Color color; const StatCard({super.key, required this.title, required this.value, required this.unit, required this.icon, required this.color}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), Text(unit, style: const TextStyle(color: Colors.black54, fontSize: 11))])); }

class AddPage extends StatefulWidget { final VoidCallback onSaved; const AddPage({super.key, required this.onSaved}); @override State<AddPage> createState() => _AddPageState(); }
class _AddPageState extends State<AddPage> {
  final form = GlobalKey<FormState>(); final carton = TextEditingController(); DateTime date = DateTime.now(); String? product; List<String> products = []; bool saving = false;
  @override void initState() { super.initState(); FactoryDb.instance.products().then((v) { if (mounted) setState(() { products = v; product = v.isNotEmpty ? v.first : null; }); }); }
  @override void dispose() { carton.dispose(); super.dispose(); }
  Future<void> pickDate() async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setState(() => date = d); }
  Future<void> save() async { if (!form.currentState!.validate() || product == null) return; setState(() => saving = true); await FactoryDb.instance.add(Production(date: DateFormat('yyyy-MM-dd').format(date), product: product!, cartons: int.parse(carton.text.trim()))); carton.clear(); setState(() { saving = false; date = DateTime.now(); }); widget.onSaved(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('উৎপাদনের তথ্য সংরক্ষণ হয়েছে'))); }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [const Text('নতুন উৎপাদন এন্ট্রি', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 5), const Text('তারিখ, পণ্য এবং কার্টনের সংখ্যা দিন', style: TextStyle(color: Colors.black54)), const SizedBox(height: 20), Card(child: Padding(padding: const EdgeInsets.all(18), child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('উৎপাদনের তারিখ'), const SizedBox(height: 8), OutlinedButton.icon(onPressed: pickDate, icon: const Icon(Icons.calendar_month), label: Text(DateFormat('dd MMMM yyyy').format(date)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), alignment: Alignment.centerLeft)), const SizedBox(height: 18), const Text('পণ্যের নাম'), const SizedBox(height: 8), DropdownButtonFormField<String>(value: product, items: products.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => product = v), decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'পণ্য নির্বাচন করুন')), const SizedBox(height: 18), const Text('কার্টনের সংখ্যা'), const SizedBox(height: 8), TextFormField(controller: carton, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'যেমন: ২৫', suffixText: 'কার্টন'), validator: (v) { final n = int.tryParse((v ?? '').trim()); if (n == null || n <= 0) return 'সঠিক কার্টন সংখ্যা লিখুন'; return null; }), if (product == flyName) const Padding(padding: EdgeInsets.only(top: 10), child: Text('চরকির হিসাব মূল উৎপাদনের মোট থেকে আলাদা থাকবে।', style: TextStyle(color: Color(0xFFB56A2A)))), const SizedBox(height: 22), FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save), label: Text(saving ? 'সংরক্ষণ হচ্ছে...' : 'উৎপাদন সংরক্ষণ করুন'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)))]))))]);
}

class HistoryPage extends StatefulWidget { final VoidCallback onChanged; const HistoryPage({super.key, required this.onChanged}); @override State<HistoryPage> createState() => _HistoryPageState(); }
class _HistoryPageState extends State<HistoryPage> { String filter = 'সব'; @override Widget build(BuildContext context) => FutureBuilder<List<Production>>(future: loadRecords(), builder: (context, snap) { final rows = (snap.data ?? []).where((r) => filter == 'সব' || (filter == 'চরকি' ? r.product == flyName : r.product != flyName)).toList(); return Column(children: [Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Row(children: [const Expanded(child: Text('উৎপাদনের ইতিহাস', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), DropdownButton<String>(value: filter, items: const [DropdownMenuItem(value: 'সব', child: Text('সব')), DropdownMenuItem(value: 'মূল উৎপাদন', child: Text('মূল উৎপাদন')), DropdownMenuItem(value: 'চরকি', child: Text('চরকি'))], onChanged: (v) => setState(() => filter = v!))])), Expanded(child: rows.isEmpty ? const EmptyState(text: 'এই তালিকায় কোনো রেকর্ড নেই।') : ListView.builder(padding: const EdgeInsets.all(12), itemCount: rows.length, itemBuilder: (_, i) => RecordTile(record: rows[i], onEdit: () => edit(rows[i]), onDelete: () => remove(rows[i]))))]); });
  Future<void> edit(Production r) async { final c = TextEditingController(text: '${r.cartons}'); final result = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(title: const Text('কার্টনের সংখ্যা পরিবর্তন'), content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'কার্টন')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')), FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(c.text)), child: const Text('সেভ'))])); if (result != null && result > 0) { await FactoryDb.instance.update(Production(id: r.id, date: r.date, product: r.product, cartons: result)); setState(() {}); widget.onChanged(); } }
  Future<void> remove(Production r) async { final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('রেকর্ড মুছবেন?'), content: Text('${r.product} — ${r.cartons} কার্টন'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('মুছুন'))])); if (ok == true) { await FactoryDb.instance.delete(r.id!); setState(() {}); widget.onChanged(); } }
}

class RecordTile extends StatelessWidget { final Production record; final VoidCallback? onEdit, onDelete; const RecordTile({super.key, required this.record, this.onEdit, this.onDelete}); @override Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: CircleAvatar(backgroundColor: record.product == flyName ? const Color(0xFFFFF0E1) : const Color(0xFFE4F3EE), child: Icon(record.product == flyName ? Icons.toys : Icons.inventory_2, color: record.product == flyName ? const Color(0xFFB56A2A) : accent)), title: Text(record.product, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(fmtDate(record.date)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${record.cartons}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(width: 3), const Text('কার্টন', style: TextStyle(fontSize: 11)), if (onEdit != null) PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? onEdit!() : onDelete!(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('পরিবর্তন')), PopupMenuItem(value: 'delete', child: Text('মুছে ফেলুন'))])]))); }

class ReportsPage extends StatefulWidget { const ReportsPage({super.key}); @override State<ReportsPage> createState() => _ReportsPageState(); }
class _ReportsPageState extends State<ReportsPage> { DateTime month = DateTime.now(); @override Widget build(BuildContext context) => FutureBuilder<List<Production>>(future: loadRecords(), builder: (context, snap) { final rows = (snap.data ?? []).where((r) => r.date.startsWith(DateFormat('yyyy-MM').format(month))).toList(); final Map<String,int> totals = {}; for (final r in rows) { totals[r.product] = (totals[r.product] ?? 0) + r.cartons; } final sorted = totals.entries.toList()..sort((a,b) => b.value.compareTo(a.value)); return ListView(padding: const EdgeInsets.all(16), children: [const Text('মাসিক উৎপাদন রিপোর্ট', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Card(child: ListTile(leading: const Icon(Icons.calendar_month), title: Text(DateFormat('MMMM yyyy').format(month)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)), IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right))]))), const SizedBox(height: 12), Row(children: [Expanded(child: StatCard(title: 'মূল উৎপাদন', value: '${mainTotal(rows)}', unit: 'কার্টন', icon: Icons.factory, color: accent)), const SizedBox(width: 10), Expanded(child: StatCard(title: 'চরকি আলাদা', value: '${flyTotal(rows)}', unit: 'কার্টন', icon: Icons.toys, color: const Color(0xFFB56A2A)))]), const SizedBox(height: 18), const Text('পণ্যভিত্তিক হিসাব', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 8), if (sorted.isEmpty) const EmptyState(text: 'এই মাসে কোনো উৎপাদন নেই।') else ...sorted.map((e) => Card(child: ListTile(title: Text(e.key), trailing: Text('${e.value} কার্টন', style: const TextStyle(fontWeight: FontWeight.bold)))))]); }); }

class ProductsPage extends StatefulWidget { final VoidCallback onChanged; const ProductsPage({super.key, required this.onChanged}); @override State<ProductsPage> createState() => _ProductsPageState(); }
class _ProductsPageState extends State<ProductsPage> { @override Widget build(BuildContext context) => FutureBuilder<List<String>>(future: FactoryDb.instance.products(), builder: (context, snap) { final products = snap.data ?? []; return Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Expanded(child: Text('পণ্যের তালিকা', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))), FilledButton.icon(onPressed: add, icon: const Icon(Icons.add), label: const Text('নতুন পণ্য'))])), Expanded(child: ListView.builder(itemCount: products.length, itemBuilder: (_, i) => Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ListTile(leading: const Icon(Icons.toys_outlined), title: Text(products[i]), trailing: products[i] == flyName ? const Chip(label: Text('আলাদা হিসাব')) : null))))]); });
  Future<void> add() async { final c = TextEditingController(); final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text('নতুন পণ্য যোগ করুন'), content: TextField(controller: c, decoration: const InputDecoration(labelText: 'পণ্যের নাম')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('যোগ করুন'))])); if (name != null && name.isNotEmpty) { await FactoryDb.instance.addProduct(name); setState(() {}); widget.onChanged(); } }
}

class EmptyState extends StatelessWidget { final String text; const EmptyState({super.key, required this.text}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox_outlined, size: 46, color: Colors.blueGrey.shade300), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54))]))); }
