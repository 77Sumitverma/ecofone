import 'dart:async';
import 'package:ecofone/models/user_profile.dart';
import 'package:ecofone/models/order_model.dart';
import 'package:ecofone/models/inventory_model.dart';
import 'package:ecofone/models/trade_in_model.dart';

abstract class BackendService {
  /// Stream live inventory updates for a particular store (or all stores)
  Stream<List<PhoneStockItem>> streamLiveInventory({String? storeId});

  /// Fetch live snapshot inventory from backend or billing API
  Future<List<PhoneStockItem>> fetchInventory({String? storeId});

  /// Stream real-time customer purchase orders for the active user
  Stream<List<PhoneOrder>> streamUserOrders(String userPhone);

  /// Send SMS OTP for mobile authentication
  Future<bool> sendOtp(String phoneNumber);

  /// Verify SMS OTP and return UserProfile with auth session
  Future<UserProfile?> verifyOtpAndLogin({
    required String phoneNumber,
    required String otp,
    String? name,
  });

  /// Place a new smartphone purchase order
  Future<PhoneOrder> createOrder(PhoneOrder order);

  /// Place an online verified order directly synced with POS API and Razorpay
  Future<PhoneOrder> createOnlinePosOrder({
    required PhoneOrder order,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    double? amount,
  });

  /// Cancel an order in cloud database and billing software
  Future<bool> cancelOrder(String orderId);

  /// Submit a customer trade-in / buyback quote to billing software & cloud backend
  Future<TradeInQuote> submitTradeInQuote(TradeInQuote quote);

  /// Dispatch automated notification to store owner / manager
  Future<bool> notifyStoreOwner(PhoneOrder order);

  /// Update user profile details in cloud database
  Future<bool> updateUserProfile(UserProfile profile);

  // Backward-compatibility wrappers
  Stream<List<PhoneOrder>> streamUserReservations(String userPhone);
  Future<PhoneOrder> createReservation(PhoneOrder reservation);
  Future<bool> cancelReservation(String reservationId);

  /// Dispose any active stream listeners or websocket connections
  void dispose();
}


