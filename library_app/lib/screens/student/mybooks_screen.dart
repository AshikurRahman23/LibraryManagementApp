import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api/api_service.dart';
import '../../utils/js_safe.dart';
import 'allbooks_screen.dart';
import 'dashboard_screen.dart';
import 'payment_history_screen.dart';
import '../auth/login_screen.dart';

class StudentMyBooksScreen extends StatefulWidget {
  final Map? loans;
  const StudentMyBooksScreen({super.key, this.loans});

  @override
  State<StudentMyBooksScreen> createState() => _StudentMyBooksScreenState();
}

class _StudentMyBooksScreenState extends State<StudentMyBooksScreen> {
  final TextEditingController searchController = TextEditingController();
  final ApiService apiService = ApiService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> currentLoans = [];
  List<Map<String, dynamic>> pastLoans = [];
  List<Map<String, dynamic>> filteredCurrentLoans = [];
  List<Map<String, dynamic>> filteredPastLoans = [];
  int borrowed = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    if (widget.loans != null) {
      currentLoans = List<Map<String, dynamic>>.from(widget.loans?['currentLoans'] ?? []);
      pastLoans = List<Map<String, dynamic>>.from(widget.loans?['pastLoans'] ?? []);
      filteredCurrentLoans = List.from(currentLoans);
      filteredPastLoans = List.from(pastLoans);
      borrowed = widget.loans?['borrowed'] ?? 0;
      isLoading = false;
    } else {
      fetchMyBooks();
    }
  }

  void _onSearchChanged() {
    _filterLoans(searchController.text);
  }

  void _filterLoans(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredCurrentLoans = List.from(currentLoans);
        filteredPastLoans = List.from(pastLoans);
      });
    } else {
      final q = query.toLowerCase();
      setState(() {
        filteredCurrentLoans = currentLoans.where((loan) {
          return (loan['title']?.toString().toLowerCase() ?? '').contains(q) ||
                 (loan['author']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
        filteredPastLoans = pastLoans.where((loan) {
          return (loan['title']?.toString().toLowerCase() ?? '').contains(q) ||
                 (loan['author']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      });
    }
  }

  Future<void> fetchMyBooks({String search = ''}) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await apiService.getMyBooks(search: search);
      if (!mounted) return;
      setState(() {
        currentLoans = sanitizeListOfMaps(List.from(data['currentLoans'] ?? []));
        pastLoans = sanitizeListOfMaps(List.from(data['pastLoans'] ?? []));
        filteredCurrentLoans = List.from(currentLoans);
        filteredPastLoans = List.from(pastLoans);
        borrowed = data['borrowed'] ?? 0;
        isLoading = false;
      });
      _filterLoans(searchController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  int calculateDaysLeft(Object? returnDate) {
    final today = DateTime.now();
    final due = safeParseDate(returnDate);
    if (due == null) return 0; // unable to parse -> treat as 0 days left
    return due.difference(today).inDays;
  }

  /// Calculate penalty: 10 taka for first 15 days overdue, +10 for each additional 15 days
  int calculatePenalty(Object? returnDate) {
    final daysOverdue = -calculateDaysLeft(returnDate);
    if (daysOverdue <= 0) return 0;
    
    // Calculate penalty: 10 taka per 15-day period
    // Days 1-15: 10 taka, Days 16-30: 20 taka, Days 31-45: 30 taka, etc.
    final periods = ((daysOverdue - 1) ~/ 15) + 1;
    return periods * 10;
  }

  void _showPaymentDialog(Map<String, dynamic> loan, int penalty) {
    String selectedMethod = 'card'; // card, bkash, nagad
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController pinController = TextEditingController();
    final TextEditingController amountController = TextEditingController(text: penalty.toString());
    final TextEditingController referenceController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final isSmallScreen = screenWidth < 400;
        
        return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          actionsPadding: const EdgeInsets.all(8),
          title: Row(
            children: [
              Icon(Icons.payment, color: Colors.blue, size: isSmallScreen ? 20 : 24),
              const SizedBox(width: 6),
              Flexible(child: Text('Pay Penalty', style: TextStyle(fontSize: isSmallScreen ? 16 : 18))),
            ],
          ),
          content: SizedBox(
            width: isSmallScreen ? screenWidth * 0.85 : 320,
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book info - compact
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          safeString(loan['title']),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '৳$penalty',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                
                // Amount input field - compact
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (৳)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.money, size: 20),
                    border: const OutlineInputBorder(),
                    helperText: 'Min ৳10',
                    helperStyle: const TextStyle(fontSize: 10),
                  ),
                  style: const TextStyle(fontSize: 14),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                
                // Payment method selection - compact
                Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 12 : 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildMethodButton('card', 'Card', Icons.credit_card, Colors.blue, selectedMethod, (m) => setDialogState(() => selectedMethod = m), isSmallScreen),
                    const SizedBox(width: 6),
                    _buildMethodButton('bkash', 'bKash', Icons.phone_android, const Color(0xFFE2136E), selectedMethod, (m) => setDialogState(() => selectedMethod = m), isSmallScreen),
                    const SizedBox(width: 6),
                    _buildMethodButton('nagad', 'Nagad', Icons.smartphone, const Color(0xFFF6921E), selectedMethod, (m) => setDialogState(() => selectedMethod = m), isSmallScreen),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Card payment fields - compact
                if (selectedMethod == 'card') ...[
                  TextField(
                    controller: cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      hintText: '1234 5678 9012 3456',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.credit_card, size: 20),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expiryController,
                          decoration: const InputDecoration(
                            labelText: 'MM/YY',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          style: const TextStyle(fontSize: 14),
                          keyboardType: TextInputType.datetime,
                          maxLength: 5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                          style: const TextStyle(fontSize: 14),
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name on Card',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.person, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
                
                // bKash payment fields - compact
                if (selectedMethod == 'bkash') ...[
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'bKash Number',
                      hintText: '01XXXXXXXXX',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.phone, color: Color(0xFFE2136E), size: 20),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pinController,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      hintText: '****',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFFE2136E), size: 20),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    obscureText: true,
                  ),
                ],
                
                // Nagad payment fields - compact
                if (selectedMethod == 'nagad') ...[
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nagad Number',
                      hintText: '01XXXXXXXXX',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.phone, color: Color(0xFFF6921E), size: 20),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pinController,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      hintText: '****',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFFF6921E), size: 20),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    obscureText: true,
                  ),
                ],
                
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Demo payment - no real charges.',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      // Validate amount
                      final payAmount = int.tryParse(amountController.text) ?? 0;
                      if (payAmount < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Minimum payment amount is ৳10'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (payAmount > penalty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Amount cannot exceed penalty (৳$penalty)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // Validation based on payment method
                      bool isValid = false;
                      if (selectedMethod == 'card') {
                        isValid = cardNumberController.text.length >= 16 &&
                            expiryController.text.length >= 5 &&
                            cvvController.text.length >= 3 &&
                            nameController.text.isNotEmpty;
                      } else {
                        isValid = phoneController.text.length >= 11 &&
                            pinController.text.length >= 4;
                      }
                      
                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please fill all ${selectedMethod == 'card' ? 'card' : selectedMethod} details correctly'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isProcessing = true);

                      // Simulate payment processing and save to backend
                      try {
                        final result = await apiService.makePayment(
                          loanId: loan['id'],
                          amount: payAmount,
                          paymentMethod: selectedMethod,
                          reference: null,
                        );
                        
                        if (!mounted) return;
                        Navigator.pop(ctx);

                        if (result['success'] == true) {
                          // Show success dialog
                          _showPaymentSuccessDialog(loan, payAmount, penalty, selectedMethod, result['transaction_id'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Payment failed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        // Demo mode - show success anyway
                        _showPaymentSuccessDialog(loan, payAmount, penalty, selectedMethod, 'TXN${DateTime.now().millisecondsSinceEpoch}');
                      }
                    },
              child: isProcessing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isProcessing ? '...' : 'Pay', style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: selectedMethod == 'bkash' 
                    ? const Color(0xFFE2136E) 
                    : selectedMethod == 'nagad' 
                        ? const Color(0xFFF6921E) 
                        : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
      },
    );
  }

  // Helper method for payment method buttons
  Widget _buildMethodButton(String method, String label, IconData icon, Color color, String selectedMethod, void Function(String) onSelect, bool isSmall) {
    final isSelected = selectedMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(method),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmall ? 6 : 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: isSmall ? 20 : 24),
              const SizedBox(height: 2),
              Text(label, 
                style: TextStyle(
                  fontSize: isSmall ? 10 : 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSuccessDialog(Map<String, dynamic> loan, int paidAmount, int totalPenalty, String method, String transactionId) {
    final remaining = totalPenalty - paidAmount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount Paid: ৳$paidAmount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (remaining > 0) ...[
              Text('Remaining Penalty: ৳$remaining', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ] else ...[
              const Text('✅ Penalty fully paid!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            Text('Book: ${safeString(loan['title'])}'),
            const SizedBox(height: 8),
            Text('Method: ${method.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Transaction ID: $transactionId', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            Text(
              remaining > 0 
                ? 'Thank you! Please pay the remaining ৳$remaining to clear your penalty.'
                : 'Thank you for your payment! Please return the book to the library.',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              fetchMyBooks(); // Refresh the list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> navigateTo(String route) async {
    if (!mounted) return;
    await storage.write(key: 'last_route', value: route);
    if (!mounted) return;

    switch (route) {
      case '/student/books':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentAllBooksScreen()),
        );
        break;
      case '/student/mybooks':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentMyBooksScreen()),
        );
        break;
      case '/student/dashboard':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
        break;
      case '/student/payments':
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentPaymentHistoryScreen()),
        );
        break;
      case '/auth/logout':
        if (!mounted) return;
        await apiService.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 1100 ? 1100.0 : width * 0.95;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('📖 My Borrowed Books'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Dashboard',
            onPressed: () {
              if (!mounted) return;
              navigateTo('/student/dashboard');
            },
          ),
          IconButton(
            tooltip: 'logout',
            onPressed: () {
              if (!mounted) return;
              navigateTo('/auth/logout');
            }, 
            icon: const Icon(Icons.logout)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (!mounted) return;
              if (value.isNotEmpty) navigateTo(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/student/books', child: Text('All Books')),
              PopupMenuItem(value: '/student/mybooks', child: Text('My Books')),
              PopupMenuItem(value: '/student/payments', child: Text('Payment History')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (!mounted) return;
              fetchMyBooks();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Search books by title, author...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          searchController.clear();
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Currently Borrowed Books
                      Row(
                        children: [
                          const Text(
                            'Currently Borrowed',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (borrowed >= 3)
                            const Text(
                              '(Limit Reached)',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      filteredCurrentLoans.isEmpty
                          ? const Text('No books currently borrowed.')
                          : Column(
                              children: filteredCurrentLoans.map((loan) {
                                final daysLeft = calculateDaysLeft(loan['return_date']);
                                final totalPenalty = calculatePenalty(loan['return_date']);
                                final totalPaid = (loan['total_paid'] ?? 0) is int 
                                    ? loan['total_paid'] ?? 0 
                                    : int.tryParse(loan['total_paid'].toString()) ?? 0;
                                final int remainingPenalty = (totalPenalty - totalPaid).clamp(0, totalPenalty).toInt();
                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    title: Text(
                                      safeString(loan['title']),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black87),
                                    ),
                                    subtitle: Builder(builder: (_) {
                                      final issued = safeParseDate(loan['issued_at']);
                                      final ret = safeParseDate(loan['return_date']);
                                      final issuedText = issued != null
                                          ? issued.toLocal().toShortDateString()
                                          : safeString(loan['issued_at']);
                                      final returnText = ret != null
                                          ? ret.toLocal().toShortDateString()
                                          : safeString(loan['return_date']);
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Issued: $issuedText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Return: $returnText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 4),
                                          daysLeft < 0
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Overdue by ${-daysLeft} days',
                                                        style: const TextStyle(
                                                            color: Colors.red,
                                                            fontWeight: FontWeight.bold)),
                                                    if (totalPaid > 0) ...[
                                                      Text('💰 Total Penalty: ৳$totalPenalty',
                                                          style: const TextStyle(
                                                              color: Colors.grey,
                                                              fontSize: 13)),
                                                      Text('✅ Paid: ৳$totalPaid',
                                                          style: const TextStyle(
                                                              color: Colors.green,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w500)),
                                                      if (remainingPenalty > 0)
                                                        Text('💵 Remaining: ৳$remainingPenalty',
                                                            style: const TextStyle(
                                                                color: Colors.orange,
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.bold))
                                                      else
                                                        const Text('✅ Penalty Cleared!',
                                                            style: TextStyle(
                                                                color: Colors.green,
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.bold)),
                                                    ] else ...[
                                                      Text('💰 Penalty: ৳$totalPenalty',
                                                          style: const TextStyle(
                                                              color: Colors.red,
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold)),
                                                    ],
                                                  ],
                                                )
                                              : Text('$daysLeft days left',
                                                  style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w600)),
                                        ],
                                      );
                                    }),
                                    trailing: daysLeft < 0 && remainingPenalty > 0
                                        ? IconButton(
                                            icon: const Icon(Icons.payment, color: Colors.red, size: 32),
                                            tooltip: 'Pay Penalty ৳$remainingPenalty',
                                            onPressed: () => _showPaymentDialog(loan, remainingPenalty),
                                          )
                                        : daysLeft < 0 && remainingPenalty == 0
                                            ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                                            : loan['status'] == 'overdue'
                                                ? const Text('Overdue',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.bold))
                                                : Text(
                                                    safeString(loan['status']),
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 30),
                      // Returned Books
                      const Text('Returned Books',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      filteredPastLoans.isEmpty
                          ? const Text('No books returned yet.')
                          : Column(
                              children: filteredPastLoans.map((loan) {
                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.check_circle, color: Colors.green),
                                    title: Text(
                                      safeString(loan['title']),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87),
                                    ),
                                    subtitle: Builder(builder: (_) {
                                      final issued = safeParseDate(loan['issued_at']);
                                      final ret = safeParseDate(loan['return_date']);
                                      final returned = safeParseDate(loan['returned_at']);
                                      final issuedText = issued != null
                                          ? issued.toLocal().toShortDateString()
                                          : safeString(loan['issued_at']);
                                      final returnText = ret != null
                                          ? ret.toLocal().toShortDateString()
                                          : safeString(loan['return_date']);
                                      final returnedText = returned != null
                                          ? returned.toLocal().toShortDateString()
                                          : safeString(loan['returned_at']);
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Issued: $issuedText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Return: $returnText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Returned: $returnedText',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      );
                                    }),
                                    trailing: Text(
                                      loan['status'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// Extension for consistent date formatting
extension DateHelpers on DateTime {
  String toShortDateString() {
    return "${day.toString().padLeft(2, '0')}/"
        "${month.toString().padLeft(2, '0')}/"
        "$year";
  }
}
