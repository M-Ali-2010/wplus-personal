enum TransactionType {
  topup,
  gift,
  donation,
  paidMessage,
  subscription,
  purchase,
  payout,
  refund,
  commission,
}

enum TransactionStatus { pending, completed, failed, refunded }

class Wallet {
  const Wallet({
    required this.balance,
    required this.currency,
    this.pendingBalance = 0,
  });

  final double balance;
  final String currency;
  final double pendingBalance;
}

class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.counterpartyName,
    this.description,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? counterpartyName;
  final String? description;
}
