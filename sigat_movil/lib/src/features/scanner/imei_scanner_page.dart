import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_controller.dart';

class ImeiScannerPage extends StatefulWidget {
  const ImeiScannerPage({super.key});

  @override
  State<ImeiScannerPage> createState() => _ImeiScannerPageState();
}

class _ImeiScannerPageState extends State<ImeiScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  late final AnimationController _lineAnim;

  bool _scanning = true;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    _lineAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _lineAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_scanning || _loading) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code == _lastScanned) return;
    _lastScanned = code;
    _buscarIMEI(code);
  }

  Future<void> _buscarIMEI(String numero) async {
    setState(() {
      _scanning = false;
      _loading = true;
      _result = null;
      _errorMessage = null;
    });

    final api = SessionScope.read(context).api;
    try {
      final raw = await api.get('/imei/numero/${Uri.encodeComponent(numero)}');
      final data = ApiClient.mapFromResponse(raw);
      setState(() {
        _loading = false;
        _result = data;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorMessage = 'Producto no encontrado para ese codigo.';
      });
    }
  }

  void _reiniciar() {
    setState(() {
      _scanning = true;
      _loading = false;
      _result = null;
      _errorMessage = null;
      _lastScanned = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Escanear IMEI',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2A44),
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_scanning && !_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5B6CF0)),
              tooltip: 'Escanear otro',
              onPressed: _reiniciar,
            ),
        ],
      ),
      body: _loading
          ? const _LoadingView()
          : _errorMessage != null
              ? _ErrorView(mensaje: _errorMessage!, onRetry: _reiniciar)
              : _result != null
                  ? _ResultView(data: _result!, onScanearOtro: _reiniciar)
                  : _ScannerView(
                      controller: _controller,
                      onDetect: _onDetect,
                      lineAnim: _lineAnim,
                    ),
    );
  }
}

// ── Vista de camara con overlay ───────────────────────────────────────────
class _ScannerView extends StatelessWidget {
  const _ScannerView({
    required this.controller,
    required this.onDetect,
    required this.lineAnim,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final Animation<double> lineAnim;

  @override
  Widget build(BuildContext context) {
    const scanW = 260.0;
    const scanH = 170.0;

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(controller: controller, onDetect: onDetect),
              // Overlay con recorte y esquinas
              CustomPaint(
                painter: _ScanOverlayPainter(scanW: scanW, scanH: scanH),
              ),
              // Linea animada de escaneo
              AnimatedBuilder(
                animation: lineAnim,
                builder: (context, _) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final cx = constraints.maxWidth / 2;
                      final cy = constraints.maxHeight / 2;
                      final top = cy - scanH / 2 +
                          lineAnim.value * (scanH - 2);
                      return Positioned(
                        left: cx - scanW / 2 + 4,
                        top: top,
                        width: scanW - 8,
                        height: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B6CF0),
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5B6CF0).withOpacity(0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          child: Column(
            children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  size: 34, color: Color(0xFF5B6CF0)),
              const SizedBox(height: 10),
              const Text(
                'Apunta la camara al codigo de barras del IMEI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'El codigo se detecta automaticamente',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  const _ScanOverlayPainter({required this.scanW, required this.scanH});

  final double scanW;
  final double scanH;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - scanW / 2;
    final top = cy - scanH / 2;
    final scanRect = Rect.fromLTWH(left, top, scanW, scanH);

    // Overlay semitransparente con recorte
    final overlayPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(10))),
    );
    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Borde del recorte
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(10)),
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Esquinas de colores
    const cornerLen = 22.0;
    const cornerW = 3.0;
    final paint = Paint()
      ..color = const Color(0xFF5B6CF0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerW
      ..strokeCap = StrokeCap.round;

    // top-left
    canvas
      ..drawLine(Offset(left, top + cornerLen), Offset(left, top), paint)
      ..drawLine(Offset(left, top), Offset(left + cornerLen, top), paint)
      // top-right
      ..drawLine(
          Offset(left + scanW - cornerLen, top), Offset(left + scanW, top), paint)
      ..drawLine(
          Offset(left + scanW, top), Offset(left + scanW, top + cornerLen), paint)
      // bottom-left
      ..drawLine(
          Offset(left, top + scanH - cornerLen), Offset(left, top + scanH), paint)
      ..drawLine(
          Offset(left, top + scanH), Offset(left + cornerLen, top + scanH), paint)
      // bottom-right
      ..drawLine(Offset(left + scanW - cornerLen, top + scanH),
          Offset(left + scanW, top + scanH), paint)
      ..drawLine(Offset(left + scanW, top + scanH - cornerLen),
          Offset(left + scanW, top + scanH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Loading ────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF5B6CF0)),
          SizedBox(height: 20),
          Text(
            'Buscando IMEI...',
            style: TextStyle(fontSize: 15, color: Color(0xFF4A5568)),
          ),
        ],
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onRetry});

  final String mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(36),
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 36, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Producto no encontrado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2A44),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5B6CF0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Escanear otro codigo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resultado ──────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  const _ResultView({required this.data, required this.onScanearOtro});

  final Map<String, dynamic> data;
  final VoidCallback onScanearOtro;

  bool get _enStock => (data['estado'] ?? '') == 'EN_STOCK';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _enStock
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              _enStock
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              size: 32,
              color: _enStock
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _enStock ? 'IMEI Encontrado' : 'IMEI no disponible',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2A44),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _enStock
                ? 'Este equipo esta disponible en stock'
                : 'Este equipo no esta disponible para venta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _enStock
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Campo('IMEI', data['numero']?.toString() ?? '—'),
                  _Campo('Producto', data['productoNombre']?.toString() ?? '—'),
                  _Campo('Marca', data['marca']?.toString() ?? '—'),
                  _Campo('Modelo', data['modelo']?.toString() ?? '—'),
                  _Campo(
                    'Estado',
                    _enStock
                        ? 'En stock'
                        : (data['estado']?.toString() ?? '—'),
                    valueColor: _enStock
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  if (data['numeroVenta'] != null)
                    _Campo('Venta', data['numeroVenta'].toString()),
                  if (data['clienteNombre'] != null)
                    _Campo('Cliente', data['clienteNombre'].toString()),
                  if (data['proveedorNombre'] != null)
                    _Campo('Proveedor', data['proveedorNombre'].toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScanearOtro,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5B6CF0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Escanear otro codigo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8898AA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1F2A44),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
