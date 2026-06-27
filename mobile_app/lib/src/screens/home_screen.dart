import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/hazard_response.dart';
import '../services/hazard_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _baseUrlController = TextEditingController(
    text: 'http://10.0.2.2:8080',
  );
  final ImagePicker _imagePicker = ImagePicker();
  final HazardApiService _hazardApiService = HazardApiService();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  Size? _selectedImageSize;
  HazardResponse? _response;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (pickedFile == null) {
      return;
    }

    final imageBytes = await pickedFile.readAsBytes();
    final imageSize = await _decodeImageSize(imageBytes);

    setState(() {
      _selectedImage = pickedFile;
      _selectedImageBytes = imageBytes;
      _selectedImageSize = imageSize;
      _response = null;
      _errorMessage = null;
    });
  }

  Future<Size> _decodeImageSize(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  Future<void> _uploadImage() async {
    final image = _selectedImage;
    final imageBytes = _selectedImageBytes;
    if (image == null || imageBytes == null) {
      setState(() {
        _errorMessage = 'Choose an image first.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final response = await _hazardApiService.detectHazard(
        baseUrl: _baseUrlController.text,
        imageFile: image,
        imageBytes: imageBytes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF090B1A)),
        child: Stack(
          children: [
            const _AmbientBackdrop(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroPanel(baseUrlController: _baseUrlController),
                    const SizedBox(height: 18),
                    _ImagePickerCard(
                      selectedImageBytes: _selectedImageBytes,
                      selectedImageSize: _selectedImageSize,
                      detections: _response?.detections ?? const [],
                      isUploading: _isUploading,
                      onPickImage: _pickImage,
                      onUploadImage: _uploadImage,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 18),
                      _ErrorCard(message: _errorMessage!),
                    ],
                    if (_response != null) ...[
                      const SizedBox(height: 18),
                      _SummaryCard(response: _response!),
                      const SizedBox(height: 18),
                      _DetectionListCard(detections: _response!.detections),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.baseUrlController});

  final TextEditingController baseUrlController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HAZARD APP',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            height: 0.92,
            color: const Color(0xFFB9B4FF).withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _GlassPanel(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF786CFF),
                            Color(0xFF35D6C8),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x44786CFF),
                            blurRadius: 26,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Campus Hazard Detector',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Upload one image, review the detected hazard, and present the final severity and recommended action in a polished demo screen.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xB8FFFFFF),
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 18),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoPill(label: 'Web + Android'),
                        _InfoPill(label: 'Bounding Boxes'),
                        _InfoPill(label: 'Multi-model Ready'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _GlassPanel(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend URL',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: baseUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'http://localhost:8080',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use localhost for web, 10.0.2.2 for the emulator, and your laptop IP for a real phone.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xB8FFFFFF),
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.selectedImageBytes,
    required this.selectedImageSize,
    required this.detections,
    required this.isUploading,
    required this.onPickImage,
    required this.onUploadImage,
  });

  final Uint8List? selectedImageBytes;
  final Size? selectedImageSize;
  final List<DetectionResult> detections;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onUploadImage;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidence Preview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a maintenance or safety photo, then run detection to draw boxes on the image.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xB8FFFFFF),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 320,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF121127),
                    Color(0xFF19153B),
                    Color(0xFF231C55),
                  ],
                ),
              ),
              child: selectedImageBytes == null
                  ? Stack(
                      children: [
                        Positioned(
                          right: -28,
                          top: -12,
                          child: Container(
                            height: 160,
                            width: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7B6DFF).withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -24,
                          bottom: -20,
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF35D6C8).withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 240,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0x33FFFFFF)),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 44,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No image selected yet.\nChoose a hazard photo from your gallery.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _ImageWithBoundingBoxes(
                      imageBytes: selectedImageBytes!,
                      imageSize: selectedImageSize,
                      detections: detections,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isUploading ? null : onPickImage,
                  child: const Text('Choose Image'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isUploading ? null : onUploadImage,
                  child: isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Scanning...'),
                          ],
                        )
                      : const Text('Detect Hazard'),
                ),
              ),
            ],
          ),
          if (selectedImageBytes != null) ...[
            const SizedBox(height: 12),
            Text(
              detections.isEmpty
                  ? 'Run detection to generate the hazard result and bounding boxes.'
                  : 'Detection overlay updated on the image preview.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0x99FFFFFF),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageWithBoundingBoxes extends StatelessWidget {
  const _ImageWithBoundingBoxes({
    required this.imageBytes,
    required this.imageSize,
    required this.detections,
  });

  final Uint8List imageBytes;
  final Size? imageSize;
  final List<DetectionResult> detections;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          imageBytes,
          fit: BoxFit.contain,
        ),
        if (imageSize != null)
          CustomPaint(
            painter: _BoundingBoxPainter(
              imageSize: imageSize!,
              detections: detections,
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.response});

  final HazardResponse response;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Detection Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _SeverityBadge(severity: response.severity),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricChip(label: 'Hazard', value: response.finalHazard),
              _MetricChip(
                label: 'Confidence',
                value: '${(response.confidence * 100).toStringAsFixed(1)}%',
              ),
              _MetricChip(label: 'Severity', value: response.severity),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0x226D63FF),
                  Color(0x2235D6C8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended action',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  response.recommendation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xCCFFFFFF),
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectionListCard extends StatelessWidget {
  const _DetectionListCard({required this.detections});

  final List<DetectionResult> detections;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model Detections',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Each card comes from the backend detection list, so future models can be added without changing this screen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xB8FFFFFF),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          if (detections.isEmpty)
            const Text('No hazard detected for this image.')
          else
            ...detections.map(
              (detection) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF121127),
                        Color(0xFF1A1638),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x22FFFFFF)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              detection.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x226D63FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              detection.modelId.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFC6C1FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniPill(
                            label:
                                'Confidence ${(detection.confidence * 100).toStringAsFixed(1)}%',
                          ),
                          _MiniPill(label: 'Class ${detection.classId}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bounding Box',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF9CB0FF),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '(${detection.boundingBox.x1.toStringAsFixed(1)}, ${detection.boundingBox.y1.toStringAsFixed(1)}) -> (${detection.boundingBox.x2.toStringAsFixed(1)}, ${detection.boundingBox.y2.toStringAsFixed(1)})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xCCFFFFFF),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6D63FF).withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF35D6C8).withValues(alpha: 0.14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCC17162F),
            Color(0xAA121127),
          ],
        ),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity.toLowerCase()) {
      'high' => const Color(0xFFFF7A59),
      'medium' => const Color(0xFFFFC857),
      'low' => const Color(0xFF35D6C8),
      _ => const Color(0xFFAAB9FF),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x226D63FF),
            Color(0x2235D6C8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x18FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFAAB9FF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x44B54832),
            Color(0x22B54832),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x55FF9887)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0x33FF9887),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Color(0xFFFFB0A1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFD5CD),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  const _BoundingBoxPainter({
    required this.imageSize,
    required this.detections,
  });

  final Size imageSize;
  final List<DetectionResult> detections;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return;
    }

    final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, size);
    final destination = Alignment.center.inscribe(fittedSizes.destination, Offset.zero & size);

    final scaleX = destination.width / imageSize.width;
    final scaleY = destination.height / imageSize.height;

    for (final detection in detections) {
      final color = _colorForLabel(detection.label);
      final rect = Rect.fromLTRB(
        destination.left + detection.boundingBox.x1 * scaleX,
        destination.top + detection.boundingBox.y1 * scaleY,
        destination.left + detection.boundingBox.x2 * scaleX,
        destination.top + detection.boundingBox.y2 * scaleY,
      );

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRect(rect, paint);

      final label = '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%';
      final paragraphStyle = ui.ParagraphStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );
      final textStyle = ui.TextStyle(
        color: Colors.white,
      );
      final builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(label);
      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: rect.width.clamp(60, 180)));

      final labelHeight = paragraph.height + 8;
      final labelWidth = paragraph.maxIntrinsicWidth + 10;
      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - labelHeight < destination.top ? rect.top : rect.top - labelHeight,
        labelWidth,
        labelHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
        Paint()..color = color,
      );
      canvas.drawParagraph(paragraph, Offset(labelRect.left + 5, labelRect.top + 4));
    }
  }

  Color _colorForLabel(String label) {
    final colors = <Color>[
      const Color(0xFFFF7A59),
      const Color(0xFF35D6C8),
      const Color(0xFF6D63FF),
      const Color(0xFFFFC857),
      const Color(0xFFE56BFF),
    ];

    return colors[label.hashCode.abs() % colors.length];
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.detections != detections;
  }
}
