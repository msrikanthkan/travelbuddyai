import 'package:flutter/material.dart';

import '../services/google_search_service.dart';

class BargainAssistantFormScreen extends StatefulWidget {
  const BargainAssistantFormScreen({super.key});

  @override
  State<BargainAssistantFormScreen> createState() => _BargainAssistantFormScreenState();
}

class _BargainAssistantFormScreenState extends State<BargainAssistantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeController = TextEditingController();
  final _askingPriceController = TextEditingController();
  String _transportType = 'taxi';
  bool _isLookingUp = false;
  String? _localSearchMessage;
  String? _lookupError;
  LocalFareEstimate? _localFareEstimate;

  @override
  void dispose() {
    _routeController.dispose();
    _askingPriceController.dispose();
    super.dispose();
  }

  Future<void> _lookupLocalPrice() async {
    if (_routeController.text.trim().isEmpty) {
      setState(() {
        _lookupError = 'Enter route to search local prices.';
      });
      return;
    }

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
      _localSearchMessage = null;
    });

    try {
      final service = GoogleSearchService();
      final result = await service.searchLocalFare(_transportType, _routeController.text.trim());
      setState(() {
        _localFareEstimate = result;
        _localSearchMessage = result.displayText;
      });
    } catch (error) {
      setState(() {
        // Surface the real error to help diagnose (API key missing, network, etc.)
        _lookupError = error?.toString() ?? 'Could not fetch local prices. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
        });
      }
    }
  }

  double? _getLocalFareEstimate() {
    return _localFareEstimate?.averageFare;
  }

  void _showNegotiationTips() {
    final price = double.tryParse(_askingPriceController.text) ?? 0;
    final estimatedPrice = _getEstimatedPrice();
    final localPrice = _getLocalFareEstimate();
    final benchmark = localPrice ?? estimatedPrice;

    final localRateText = localPrice != null
        ? 'Local search rate: ₹${localPrice.toStringAsFixed(0)}'
        : 'Estimated local rate: ₹${estimatedPrice.toStringAsFixed(0)}';

    String message;
    if (price > benchmark * 1.5) {
      message = '$localRateText\n\nThat is too high!\nSay: "Please adjust to the local rate around ₹${benchmark.toStringAsFixed(0)}."';
    } else if (price > benchmark * 1.2) {
      message = '$localRateText\n\nSlightly high.\nSay: "Can you come down a bit to around ₹${benchmark.toStringAsFixed(0)}?"';
    } else {
      message = '$localRateText\n\nFair price! You can offer to settle at around ₹${benchmark.toStringAsFixed(0)}.';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Negotiation Tip'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  double _getEstimatedPrice() {
    // Simple estimation: ₹10 per km for taxi, ₹8 per km for auto
    final multiplier = _transportType == 'taxi' ? 10.0 : 8.0;
    return 50 + (10 * multiplier); // base + 10km estimate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bargain Assistant'),
        backgroundColor: const Color(0xFF00B4DB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _transportType,
                decoration: const InputDecoration(labelText: 'Transport type'),
                items: const [
                  DropdownMenuItem(value: 'taxi', child: Text('Taxi')),
                  DropdownMenuItem(value: 'auto', child: Text('Auto-rickshaw')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _transportType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _routeController,
                decoration: const InputDecoration(labelText: 'Route (e.g., Airport to Hotel)'),
                validator: (value) => value == null || value.isEmpty ? 'Enter route' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _localSearchMessage ?? 'Local fare not searched yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: _localSearchMessage != null ? Colors.black87 : Colors.black45,
                          ),
                        ),
                        if (_lookupError != null) ...[
                          const SizedBox(height: 6),
                          Text(_lookupError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4DB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLookingUp ? null : _lookupLocalPrice,
                      child: _isLookingUp
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Lookup', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _askingPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price asked by driver (₹)'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter price';
                  if (double.tryParse(value) == null) return 'Enter valid price';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                _localFareEstimate != null
                    ? 'Local search estimate: ${_localFareEstimate!.displayText}'
                    : 'Estimated local price: ₹${_getEstimatedPrice().toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF00B4DB)),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4DB),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _showNegotiationTips();
                  }
                },
                child: const Text('Get Negotiation Tips', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
