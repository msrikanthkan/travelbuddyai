import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/route_model.dart';
import '../models/toll_plaza_model.dart';
import '../models/vehicle_profile_model.dart';
import '../services/toll_service.dart';

class RouteDetailsScreen extends StatefulWidget {
  final RouteDetails route;
  final VehicleProfile? vehicle;

  const RouteDetailsScreen({
    super.key,
    required this.route,
    this.vehicle,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  static const _purple = Color(0xFF7F00FF);

  final _tollService = TollService();

  List<TollPlaza> _tollPlazas = [];
  bool _loadingTolls = true;
  bool _costExpanded = false;
  bool _tollsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadTolls();
  }

  Future<void> _loadTolls() async {
    final plazas = await _tollService.getTollPlazasOnRoute(widget.route);
    if (mounted) {
      setState(() {
        _tollPlazas = plazas;
        _loadingTolls = false;
      });
    }
  }

  Future<void> _shareRoute() async {
    final route = widget.route;
    final msg = StringBuffer();
    msg.writeln('🚗 Road Trip Co-Pilot — TravelBuddyAI');
    msg.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    msg.writeln('📍 From: ${route.origin}');
    msg.writeln('📍 To:   ${route.destination}');
    msg.writeln('📏 Distance: ${route.formattedDistance}');
    msg.writeln('⏱  Duration: ${route.formattedDuration}');
    msg.writeln('${route.routeTypeIcon} Route: ${route.routeTypeName}');
    msg.writeln();
    msg.writeln('💰 Cost Estimate:');
    msg.writeln('   ⛽ Fuel:  ${route.formattedFuelCost}');
    msg.writeln('   🛣  Tolls: ${route.formattedTollCost}');
    msg.writeln('   💳 Total: ${route.formattedTotalCost}');
    msg.writeln();
    msg.writeln('Planned with TravelBuddyAI 🤖');

    await Share.share(msg.toString(), subject: 'My road trip: ${route.origin} → ${route.destination}');
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _shareRoute,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRouteSummaryCard(route),
            const SizedBox(height: 16),
            _buildMapPlaceholder(route),
            const SizedBox(height: 16),
            _buildCostBreakdown(route),
            const SizedBox(height: 16),
            _buildTollSection(route),
            const SizedBox(height: 16),
            if (widget.vehicle != null) _buildVehicleInfo(),
            const SizedBox(height: 24),
            _buildActionButtons(route),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Summary card ─────────────────────────────────────────────────────────

  Widget _buildRouteSummaryCard(RouteDetails route) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F00FF), Color(0xFF9B30FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(route.routeTypeIcon,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                route.routeTypeName,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.trip_origin, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route.origin,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  width: 2,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: Colors.white38,
                ),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.place, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route.destination,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryChip(Icons.straighten, route.formattedDistance, 'Distance'),
              _summaryChip(Icons.schedule, route.formattedDuration, 'Duration'),
              _summaryChip(Icons.currency_rupee, route.formattedTotalCost, 'Est. Cost'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  // ── Map placeholder ───────────────────────────────────────────────────────

  Widget _buildMapPlaceholder(RouteDetails route) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0A8FF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, color: _purple, size: 44),
          const SizedBox(height: 8),
          const Text(
            'Interactive Map',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C1EA8)),
          ),
          const SizedBox(height: 4),
          Text(
            '${route.origin} → ${route.destination}',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Map view coming in next release',
            style: TextStyle(fontSize: 11, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  // ── Cost breakdown ────────────────────────────────────────────────────────

  Widget _buildCostBreakdown(RouteDetails route) {
    return _expandableCard(
      title: '💰 Cost Breakdown',
      isExpanded: _costExpanded,
      onToggle: () => setState(() => _costExpanded = !_costExpanded),
      child: Column(
        children: [
          _costRow('⛽ Fuel', route.formattedFuelCost),
          _costRow('🛣️ Tolls (estimated)', route.formattedTollCost),
          const Divider(height: 20),
          _costRow('💳 Total', route.formattedTotalCost, bold: true),
          if (widget.vehicle != null) ...[
            const SizedBox(height: 8),
            _infoNote(
              '${_litersNeeded(route, widget.vehicle!).toStringAsFixed(1)} L '
              'of fuel needed for ${widget.vehicle!.averageMileageKmpl} kmpl vehicle',
            ),
          ],
        ],
      ),
    );
  }

  Widget _costRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 15 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: bold ? _purple : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  // ── Toll plazas ───────────────────────────────────────────────────────────

  Widget _buildTollSection(RouteDetails route) {
    return _expandableCard(
      title: '🛣️ Toll Plazas on Route',
      badge: _loadingTolls ? null : '${_tollPlazas.length}',
      isExpanded: _tollsExpanded,
      onToggle: () => setState(() => _tollsExpanded = !_tollsExpanded),
      child: _loadingTolls
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: _purple, strokeWidth: 2),
              ),
            )
          : _tollPlazas.isEmpty
              ? _infoNote('No toll plazas found on this route.')
              : Column(
                  children: _tollPlazas.take(10).map((plaza) {
                    return _tollPlazaRow(plaza);
                  }).toList(),
                ),
    );
  }

  Widget _tollPlazaRow(TollPlaza plaza) {
    final carCharge = plaza.chargeFor(TollVehicleType.car);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              plaza.highwayLabel,
              style: const TextStyle(
                  fontSize: 10, color: _purple, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plaza.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    if (plaza.hasFastag)
                      const Text('FASTag  ',
                          style: TextStyle(
                              fontSize: 11, color: Colors.green)),
                    Text(plaza.operatingHours,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${carCharge.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ── Vehicle info ──────────────────────────────────────────────────────────

  Widget _buildVehicleInfo() {
    final v = widget.vehicle!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0A8FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car_filled, color: _purple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.displayName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text(
                  '${v.averageMileageKmpl} kmpl · '
                  '${v.fuelTankCapacityLiters.toStringAsFixed(0)}L tank · '
                  'Range: ${v.maxRangeKm.toStringAsFixed(0)} km',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(RouteDetails route) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              // Placeholder: Navigation integration – future story
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigation coming in a future release.'),
                ),
              );
            },
            icon: const Icon(Icons.navigation_outlined),
            label: const Text('Start Navigation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareRoute,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: _purple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Placeholder: save to trips – Story 4.2
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Save route coming in a future release.')),
                  );
                },
                icon: const Icon(Icons.bookmark_border, size: 18),
                label: const Text('Save Route'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  side: const BorderSide(color: Colors.black26),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _expandableCard({
    required String title,
    String? badge,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              fontSize: 12,
                              color: _purple,
                              fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _infoNote(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  double _litersNeeded(RouteDetails route, VehicleProfile vehicle) {
    return route.totalDistanceKm / vehicle.averageMileageKmpl;
  }
}

// Made with Bob
