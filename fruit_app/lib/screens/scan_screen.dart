import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/fruit_prediction.dart';
import '../providers/prediction_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/prediction_service.dart';
import '../services/weather_service.dart';
import '../theme/app_colors.dart';
import 'detail_screen.dart';
import 'history_screen.dart';

// ── Theme-aware color helper ──────────────────────────────────────────────────
// Call _col(context) once at the top of every build method.
_Palette _col(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final isDark = cs.brightness == Brightness.dark;
  return _Palette(
    bg:       cs.surface,
    fg:       cs.onSurface,
    primary:  cs.primary,
    onPrimary: cs.onPrimary,
    secondary: cs.secondary,
    card:     cs.surfaceContainer,
    border:   cs.outline,
    muted:    isDark ? AppDarkColors.muted : AppColors.muted,
    mutedFg:  isDark ? AppDarkColors.mutedForeground : AppColors.mutedForeground,
    isDark:   isDark,
  );
}

class _Palette {
  final Color bg, fg, primary, onPrimary, secondary, card, border, muted, mutedFg;
  final bool isDark;
  const _Palette({
    required this.bg, required this.fg, required this.primary,
    required this.onPrimary, required this.secondary, required this.card,
    required this.border, required this.muted, required this.mutedFg,
    required this.isDark,
  });
}

// ── API status enum ───────────────────────────────────────────────────────────

enum _ApiStatus { checking, connected, localMode }

// ── Screen ────────────────────────────────────────────────────────────────────

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  // Image
  String? _imageUri;
  final _picker = ImagePicker();

  // Metadata
  final _fruitTypeController = TextEditingController();
  String _storageMethod = 'room_temperature';
  DateTime? _selectedDate;
  String _lightExposure = 'shaded';
  String _airflow = 'open_shelf';

  // Weather
  double? _weatherTemp;
  double? _weatherHumidity;
  String? _weatherLocation;
  bool _isFetchingWeather = false;
  String? _weatherError;

  // UI state
  bool _isAnalyzing = false;
  bool _showMetadata = false;

  // API badge
  _ApiStatus _apiStatus = _ApiStatus.checking;
  String _apiLabel = 'Checking…';

  @override
  void initState() {
    super.initState();
    _checkApiConnection();
  }

  @override
  void dispose() {
    _fruitTypeController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _checkApiConnection() async {
    if (!ApiService.isConfigured) {
      setState(() { _apiStatus = _ApiStatus.localMode; _apiLabel = 'Local mode'; });
      return;
    }
    final health = await ApiService.checkHealth();
    if (!mounted) return;
    if (health != null) {
      setState(() {
        _apiStatus = _ApiStatus.connected;
        _apiLabel = 'API · CNN: ${health['cnn_model'] ?? 'stub'} · LLM: ${health['llm_provider'] ?? 'stub'}';
      });
    } else {
      setState(() { _apiStatus = _ApiStatus.localMode; _apiLabel = 'API unreachable — local mode'; });
    }
  }

  Future<void> _pickImage({required bool useCamera}) async {
    try {
      final result = await _picker.pickImage(
        source: useCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
      if (result != null) setState(() => _imageUri = result.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open image picker.')));
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _fetchWeather() async {
    setState(() { _isFetchingWeather = true; _weatherError = null; });
    final data = await WeatherService.fetchCurrentWeather();
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _weatherTemp = data.temperature;
        _weatherHumidity = data.humidity;
        _weatherLocation = data.locationDisplay;
        _isFetchingWeather = false;
      });
    } else {
      setState(() {
        _isFetchingWeather = false;
        _weatherError = 'Could not fetch weather. Check location permissions.';
      });
    }
  }

  Future<void> _handleAnalyze() async {
    if (_imageUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture a fruit image first.')));
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      final prediction = await ApiService.predictFruit(PredictionInput(
        imageUri: _imageUri!,
        fruitType: _fruitTypeController.text.isEmpty ? null : _fruitTypeController.text,
        storageMethod: _storageMethod,
        purchaseDate: _selectedDate != null
            ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
            : null,
        temperature: _weatherTemp?.toStringAsFixed(1),
        humidity: _weatherHumidity?.toStringAsFixed(0),
        lightExposure: _lightExposure,
        airflow: _airflow,
      ));
      if (!mounted) return;
      await context.read<PredictionProvider>().addPrediction(prediction);
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailScreen(predictionId: prediction.id)));
      setState(() {
        _imageUri = null;
        _fruitTypeController.clear();
        _storageMethod = 'room_temperature';
        _selectedDate = null;
        _lightExposure = 'shaded';
        _airflow = 'open_shelf';
        _weatherTemp = null;
        _weatherHumidity = null;
        _weatherLocation = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis failed. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = _col(context);
    final themeNotifier = context.watch<ThemeNotifier>();

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton.small(
        onPressed: themeNotifier.toggle,
        backgroundColor: c.secondary,
        elevation: 3,
        tooltip: c.isDark ? 'Switch to light mode' : 'Switch to dark mode',
        child: Icon(
          c.isDark ? FeatherIcons.sun : FeatherIcons.moon,
          color: c.primary,
          size: 18,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(c, themeNotifier),
              const SizedBox(height: 24),
              _buildImageArea(c),
              const SizedBox(height: 16),
              _buildPickerButtons(c),
              const SizedBox(height: 12),
              _buildMetadataToggle(c),
              // ── Animated expand/collapse ──────────────────────────────────
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeInOut,
                  child: _showMetadata
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 4),
                          child: _buildMetadataContent(c),
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ),
              const SizedBox(height: 4),
              _buildAnalyzeButton(c),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(_Palette c, ThemeNotifier themeNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FRESHSENSE',
                style: TextStyle(
                    fontSize: 11, letterSpacing: 1.5, color: c.mutedFg)),
            const SizedBox(height: 2),
            Text('Scan a Fruit',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, color: c.fg)),
            const SizedBox(height: 6),
            _ApiStatusBadge(status: _apiStatus, label: _apiLabel),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.secondary, shape: BoxShape.circle),
            child: Icon(FeatherIcons.list, color: c.primary, size: 20),
          ),
        ),
      ],
    );
  }

  // ── Image area ─────────────────────────────────────────────────────────────

  Widget _buildImageArea(_Palette c) {
    if (_imageUri != null) {
      return Center(
        child: Stack(
          children: [
            Hero(
              tag: 'fruit_image',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(File(_imageUri!),
                    width: 260, height: 260, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: GestureDetector(
                onTap: () => setState(() => _imageUri = null),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                      color: c.card.withOpacity(0.9), shape: BoxShape.circle),
                  child: Icon(FeatherIcons.x, size: 14, color: c.fg),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Container(
        width: 260, height: 200,
        decoration: BoxDecoration(
          color: c.muted,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: c.secondary, shape: BoxShape.circle),
              child: Icon(FeatherIcons.camera, size: 30, color: c.primary),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Add a fruit photo to analyze',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: c.mutedFg, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Picker buttons ─────────────────────────────────────────────────────────

  Widget _buildPickerButtons(_Palette c) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Camera', icon: FeatherIcons.camera,
            bg: c.primary, fg: c.onPrimary,
            onTap: () => _pickImage(useCamera: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Gallery', icon: FeatherIcons.image,
            bg: c.secondary, fg: c.primary,
            onTap: () => _pickImage(useCamera: false),
          ),
        ),
      ],
    );
  }

  // ── Metadata toggle ────────────────────────────────────────────────────────

  Widget _buildMetadataToggle(_Palette c) {
    return GestureDetector(
      onTap: () => setState(() => _showMetadata = !_showMetadata),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.muted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _showMetadata ? c.primary.withOpacity(0.4) : c.border),
        ),
        child: Row(
          children: [
            Icon(FeatherIcons.sliders,
                size: 15, color: _showMetadata ? c.primary : c.mutedFg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _showMetadata ? 'Hide optional details' : 'Add optional details',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _showMetadata ? c.primary : c.mutedFg),
              ),
            ),
            AnimatedRotation(
              turns: _showMetadata ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Icon(FeatherIcons.chevronDown,
                  size: 16, color: _showMetadata ? c.primary : c.mutedFg),
            ),
          ],
        ),
      ),
    );
  }

  // ── Metadata content ───────────────────────────────────────────────────────

  Widget _buildMetadataContent(_Palette c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // ── Fruit type ───────────────────────────────────────────────────────
        _SectionCard(
          icon: FeatherIcons.tag,
          title: 'Fruit Type',
          subtitle: 'Optional hint to improve classification accuracy',
          child: TextField(
            controller: _fruitTypeController,
            style: TextStyle(color: c.fg, fontSize: 14),
            decoration: const InputDecoration(
                hintText: 'e.g. banana, mango, apple…'),
          ),
        ),
        const SizedBox(height: 10),

        // ── Purchase date ────────────────────────────────────────────────────
        _SectionCard(
          icon: FeatherIcons.calendar,
          title: 'Purchase Date',
          subtitle: 'Used to calculate days since purchase',
          child: _DatePickerRow(
            selectedDate: _selectedDate,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(height: 10),

        // ── Storage method ───────────────────────────────────────────────────
        _SectionCard(
          icon: FeatherIcons.archive,
          title: 'Storage Method',
          subtitle: 'Where is the fruit being kept?',
          child: _ChipGroup(
            options: const [
              ('room_temperature', 'Room Temp', FeatherIcons.sun),
              ('refrigerator', 'Fridge', FeatherIcons.thermometer),
              ('freezer', 'Freezer', FeatherIcons.wind),
            ],
            selected: _storageMethod,
            onChanged: (v) => setState(() => _storageMethod = v),
          ),
        ),
        const SizedBox(height: 10),

        // ── Light exposure ───────────────────────────────────────────────────
        _SectionCard(
          icon: FeatherIcons.sun,
          title: 'Light Exposure',
          subtitle: 'How much light does the fruit receive?',
          child: _ChipGroup(
            options: const [
              ('direct_sunlight', 'Direct Sun', FeatherIcons.sunrise),
              ('shaded', 'Shaded', FeatherIcons.cloud),
              ('dark_cupboard', 'Dark Cupboard', FeatherIcons.moon),
            ],
            selected: _lightExposure,
            onChanged: (v) => setState(() => _lightExposure = v),
          ),
        ),
        const SizedBox(height: 10),

        // ── Airflow ──────────────────────────────────────────────────────────
        _SectionCard(
          icon: FeatherIcons.wind,
          title: 'Airflow & Ventilation',
          subtitle: 'Airflow affects moisture loss and mold risk',
          child: _ChipGroup(
            options: const [
              ('open_shelf', 'Open Shelf', FeatherIcons.alignJustify),
              ('ventilated_basket', 'Ventilated', FeatherIcons.grid),
              ('closed_drawer', 'Closed Drawer', FeatherIcons.minus),
            ],
            selected: _airflow,
            onChanged: (v) => setState(() => _airflow = v),
          ),
        ),
        const SizedBox(height: 10),

        // ── Weather ──────────────────────────────────────────────────────────
        _SectionCard(
          icon: FeatherIcons.cloudRain,
          title: 'Outdoor Weather',
          subtitle: 'Auto-fetched from your location · outdoor readings only',
          child: _WeatherPanel(
            temp: _weatherTemp,
            humidity: _weatherHumidity,
            location: _weatherLocation,
            isFetching: _isFetchingWeather,
            error: _weatherError,
            onFetch: _fetchWeather,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Analyze button ─────────────────────────────────────────────────────────

  Widget _buildAnalyzeButton(_Palette c) {
    final enabled = !_isAnalyzing && _imageUri != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _handleAnalyze : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _imageUri != null ? c.primary : c.muted,
          foregroundColor: _imageUri != null ? c.onPrimary : c.mutedFg,
          disabledBackgroundColor: c.muted,
          disabledForegroundColor: c.mutedFg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isAnalyzing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 10),
                  Text('Analyzing…',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FeatherIcons.zap,
                      size: 18,
                      color: _imageUri != null ? c.onPrimary : c.mutedFg),
                  const SizedBox(width: 10),
                  Text('Analyze Shelf Life',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _imageUri != null ? c.onPrimary : c.mutedFg)),
                ],
              ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = _col(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: c.secondary, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 15, color: c.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.fg)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 11, color: c.mutedFg)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Date picker row ───────────────────────────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _DatePickerRow({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = _col(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.muted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selectedDate != null
                  ? c.primary.withOpacity(0.4)
                  : c.border),
        ),
        child: Row(
          children: [
            Icon(FeatherIcons.calendar,
                size: 16,
                color: selectedDate != null ? c.primary : c.mutedFg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate!.day} / ${selectedDate!.month} / ${selectedDate!.year}'
                    : 'Tap to select purchase date',
                style: TextStyle(
                    fontSize: 14,
                    color: selectedDate != null ? c.fg : c.mutedFg),
              ),
            ),
            if (selectedDate != null)
              Icon(FeatherIcons.checkCircle, size: 15, color: c.primary),
          ],
        ),
      ),
    );
  }
}

// ── Chip group ────────────────────────────────────────────────────────────────

class _ChipGroup extends StatelessWidget {
  final List<(String, String, IconData)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = _col(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return GestureDetector(
          onTap: () => onChanged(opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? c.primary : c.muted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? c.primary : c.border, width: 1.5),
              boxShadow: isSelected
                  ? [BoxShadow(color: c.primary.withOpacity(0.25),
                        blurRadius: 6, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt.$3,
                    size: 12,
                    color: isSelected ? c.onPrimary : c.mutedFg),
                const SizedBox(width: 5),
                Text(opt.$2,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? c.onPrimary : c.mutedFg)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Weather panel ─────────────────────────────────────────────────────────────

class _WeatherPanel extends StatelessWidget {
  final double? temp;
  final double? humidity;
  final String? location;
  final bool isFetching;
  final String? error;
  final VoidCallback onFetch;

  const _WeatherPanel({
    required this.temp, required this.humidity, required this.location,
    required this.isFetching, required this.error, required this.onFetch,
  });

  @override
  Widget build(BuildContext context) {
    final c = _col(context);

    if (isFetching) {
      return Row(
        children: [
          SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: c.primary)),
          const SizedBox(width: 10),
          Text('Fetching local weather…',
              style: TextStyle(fontSize: 13, color: c.mutedFg)),
        ],
      );
    }

    if (temp != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.mapPin, size: 12, color: c.mutedFg),
              const SizedBox(width: 4),
              Expanded(
                child: Text(location ?? '',
                    style: TextStyle(fontSize: 11, color: c.mutedFg)),
              ),
              GestureDetector(
                onTap: onFetch,
                child: Row(
                  children: [
                    Icon(FeatherIcons.refreshCw, size: 12, color: c.primary),
                    const SizedBox(width: 4),
                    Text('Refresh',
                        style: TextStyle(
                            fontSize: 11,
                            color: c.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WeatherTile(
                    icon: FeatherIcons.thermometer,
                    label: 'Temperature',
                    value: '${temp!.toStringAsFixed(1)}°C'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeatherTile(
                    icon: FeatherIcons.droplet,
                    label: 'Humidity',
                    value: '${humidity!.toStringAsFixed(0)}%'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.muted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.info, size: 12, color: c.mutedFg),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Outdoor readings only. Indoor conditions are estimated from your storage selection above.',
                    style: TextStyle(fontSize: 10, color: c.mutedFg),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onFetch,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: c.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FeatherIcons.mapPin, size: 14, color: c.primary),
                const SizedBox(width: 8),
                Text('Fetch from my location',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.primary)),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(FeatherIcons.alertCircle,
                  size: 12, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(error!,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WeatherTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = _col(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: c.mutedFg),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(fontSize: 10, color: c.mutedFg)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.fg)),
        ],
      ),
    );
  }
}

// ── Shared action button ──────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg, fg;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.icon,
    required this.bg, required this.fg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: fg, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── API status badge ──────────────────────────────────────────────────────────

class _ApiStatusBadge extends StatelessWidget {
  final _ApiStatus status;
  final String label;

  const _ApiStatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = _col(context);

    final Color dotColor;
    final Color bgColor;

    switch (status) {
      case _ApiStatus.checking:
        dotColor = c.mutedFg;
        bgColor = c.muted;
      case _ApiStatus.connected:
        dotColor = c.primary;
        bgColor = c.secondary;
      case _ApiStatus.localMode:
        dotColor = const Color(0xFFE09D45);
        bgColor = c.isDark
            ? const Color(0xFF2C1F08)
            : const Color(0xFFFBF3E6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          status == _ApiStatus.checking
              ? SizedBox(
                  width: 8, height: 8,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: dotColor))
              : Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: dotColor)),
        ],
      ),
    );
  }
}
