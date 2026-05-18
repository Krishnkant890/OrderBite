import 'dart:async';
import 'dart:collection';
import 'package:get/get.dart';
import 'printer_service.dart';
import 'logger_service.dart';


class PrintJob {
  final Map<String, dynamic> order;
  int retryCount;
  final DateTime createdAt;

  PrintJob({
    required this.order,
    this.retryCount = 0,
  }) : createdAt = DateTime.now();
}

class PrintQueueService extends GetxService {
  final PrinterService _printerService = Get.find<PrinterService>();
  final Queue<PrintJob> _queue = Queue<PrintJob>();
  bool _isProcessing = false;
  static const int maxRetries = 3;

  void addToQueue(Map<String, dynamic> order) {
    final orderId = order['id'] ?? 'Unknown';
    _queue.add(PrintJob(order: order));
    LoggerService.to.log("QUEUE ADD: Order #$orderId added. Total in queue: ${_queue.length}");
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    LoggerService.to.log("QUEUE START: Processing ${_queue.length} pending jobs");
    
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.first;
        final orderId = job.order['id'] ?? 'Unknown';
        LoggerService.to.log("QUEUE JOB START: Order #$orderId (Retry Count: ${job.retryCount})");

        try {
          // PrinterService.autoPrintOrder is now Future<bool> with 15s timeout
          final success = await _printerService.autoPrintOrder(job.order);
          
          if (success) {
            _queue.removeFirst();
            LoggerService.to.log("QUEUE JOB SUCCESS: Order #$orderId finished and removed");
          } else {
            LoggerService.to.log("QUEUE JOB FAILURE: Order #$orderId failed to print");
            _handleFailure(job);
            // Longer delay after failure to allow hardware to reset/recover
            await Future.delayed(const Duration(seconds: 5));
          }
        } catch (e) {
          LoggerService.to.log("QUEUE JOB ERROR: Order #$orderId exception: $e");
          _handleFailure(job);
          await Future.delayed(const Duration(seconds: 5));
        }
        
        // Brief pause between jobs to prevent buffer overflow on thermal printers
        if (_queue.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }
    } finally {
      _isProcessing = false;
      LoggerService.to.log("QUEUE IDLE: All jobs processed, processor reset");
    }
  }

  void _handleFailure(PrintJob job) {
    final orderId = job.order['id'] ?? 'Unknown';
    if (job.retryCount < maxRetries) {
      job.retryCount++;
      LoggerService.to.log("QUEUE RETRY: Order #$orderId moving to end of queue (Attempt ${job.retryCount}/$maxRetries)");
      
      // Move failing job to end of queue so it doesn't block other orders if queue is long
      _queue.removeFirst();
      _queue.addLast(job);
    } else {
      LoggerService.to.log("QUEUE DISCARD: Max retries reached for Order #$orderId. Discarding.");
      _queue.removeFirst();
    }
  }
}
