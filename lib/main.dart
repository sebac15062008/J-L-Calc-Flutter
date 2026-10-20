import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

void main() {
  runApp(const JLCalcApp());
}

class JLCalcApp extends StatelessWidget {
  const JLCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J&L Calc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF202020),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: const WidgetStatePropertyAll(true),
          trackVisibility: const WidgetStatePropertyAll(true),
          thickness: WidgetStatePropertyAll(16),
          radius: const Radius.circular(8),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return const Color(0xFF8A8A8A);
            if (states.contains(WidgetState.dragged)) return const Color(0xFFB0B0B0);
            return const Color(0xFF6A6A6A);
          }),
          trackColor: const WidgetStatePropertyAll(Colors.transparent),
          trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E3A8A),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF202020),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ===================== Paleta =====================
const Color kCalcBg = Color(0xFF202020);
const Color kNumBg = Color(0xFF3B3B3B);
const Color kNumHover = Color(0xFF4A4A4A);
const Color kFnBg = Color(0xFF333333);
const Color kFnHover = Color(0xFF454545);
const Color kEqualsBg = Color(0xFFF59E0B);
const Color kEqualsHover = Color(0xFFFBBF24);
const Color kText = Color(0xFFFFFFFF);
const Color kTextSec = Color(0xFFA0A0A0);
const Color kPrimario = Color(0xFF1E3A8A);
const Color kAcento = Color(0xFFF59E0B);

// Fuerza la inclusión del icono de retroceso (evita tree-shaking)
const IconData _kBackspaceIcon = IconData(0xE0C6, fontFamily: 'MaterialIcons');
const IconData _kHistoryIcon = IconData(0xE889, fontFamily: 'MaterialIcons');

// ===================== Home =====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<PrintingPageState> _printingKey = GlobalKey<PrintingPageState>();
  final GlobalKey _impTabKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  double? _hintLeft;

  final List<_HistEntry> _historial = [];
  bool _sidebarOpen = false;
  final GlobalKey<CalculatorPageState> _calcKey = GlobalKey<CalculatorPageState>();

  File get _historyFile {
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    return File('$home\\.jlcalc_history.txt');
  }

  void _loadHistory() {
    try {
      final f = _historyFile;
      if (f.existsSync()) {
        final lines = f.readAsLinesSync();
        _historial.clear();
        for (final l in lines) {
          if (l.trim().isEmpty) continue;
          final i = l.lastIndexOf('|');
          if (i > 0) {
            _historial.add(_HistEntry(l.substring(0, i), l.substring(i + 1)));
          } else {
            _historial.add(_HistEntry(l, ''));
          }
        }
      }
    } catch (_) {}
  }

  void _saveHistory() {
    try {
      _historyFile.writeAsStringSync(_historial.map((e) => '${e.expr}|${e.result}').join('\n'));
    } catch (_) {}
  }

  void _addHistory(String expr, String result) {
    setState(() => _historial.insert(0, _HistEntry(expr, result)));
    _saveHistory();
  }

  void _clearHistory() {
    setState(() => _historial.clear());
    try {
      if (_historyFile.existsSync()) _historyFile.deleteSync();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 0) {
        _printingKey.currentState?.resetear();
      }
    });
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHint();
    });
  }

  void _measureHint() {
    final tabBox = _impTabKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (tabBox == null || stackBox == null) return;
    final tabPos = tabBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final tabWidth = tabBox.size.width;
    final hintWidth = 130.0;
    double left = tabPos.dx + (tabWidth - hintWidth) / 2;
    if (left < 0) left = 0;
    if (left + hintWidth > stackBox.size.width) left = stackBox.size.width - hintWidth;
    if (mounted) setState(() => _hintLeft = left);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCalcBg,
      body: Stack(
        key: _stackKey,
        children: [
          Column(
            children: [
              // Encabezado fijo (no escala)
              Container(
                color: kCalcBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'J&L Calc',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Pestañas fijas (no escalan)
              Container(
                color: kCalcBg,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: kAcento,
                  dividerColor: const Color(0xFF555555),
                  dividerHeight: 1,
                  overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.10)),
                  splashFactory: NoSplash.splashFactory,
                  tabs: [
                    Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calculate_outlined, size: 18), const SizedBox(width: 4), const Text('Calculadora')])),
                    Tab(key: _impTabKey, child: _PulsingTab(controller: _tabController)),
                  ],
                ),
              ),
              // Contenido escalable
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final windowH = MediaQuery.of(context).size.height;
                    final scale = (windowH / 720.0).clamp(0.6, 1.6);
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: scale),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          CalculatorPage(
                            key: _calcKey,
                            onRecientes: () => setState(() => _sidebarOpen = true),
                            onAddHistory: _addHistory,
                          ),
                          PrintingPage(key: _printingKey),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_hintLeft != null)
            Positioned(
              top: 4,
              left: _hintLeft!,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Calcula las impresiones',
                    style: TextStyle(
                      color: kAcento,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\u2193',
                    style: TextStyle(
                      color: kAcento,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Sidebar Recientes (pantalla completa de alto, animado)
          AnimatedOpacity(
            opacity: _sidebarOpen ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _sidebarOpen
                ? GestureDetector(
                    onTap: () => setState(() => _sidebarOpen = false),
                    child: Container(color: Colors.black),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _sidebarOpen ? 0 : -260,
            top: 0,
            bottom: 0,
            child: Container(
              width: 260,
              color: const Color(0xFF1E1E1E),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF2A2A2A),
                    child: Row(
                      children: [
                        const Text('Recientes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        // Boton Cerrar (misma forma que Limpiar historial pero sin fondo)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _sidebarOpen = false),
                            borderRadius: BorderRadius.circular(4),
                            hoverColor: Colors.white.withValues(alpha: 0.12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Cerrar', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  SizedBox(width: 6),
                                  Icon(Icons.close, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _historial.isEmpty
                        ? const Center(child: Text('Sin operaciones recientes', style: TextStyle(color: kTextSec, fontSize: 13)))
                        : ListView.builder(
                            itemCount: _historial.length,
                            itemBuilder: (ctx, i) {
                              final e = _historial[i];
                              return InkWell(
                                onTap: () {
                                  _calcKey.currentState?.setValorDesdeHistorial(e.result);
                                  setState(() => _sidebarOpen = false);
                                },
                                hoverColor: Colors.white.withValues(alpha: 0.08),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(e.expr,
                                          style: const TextStyle(color: kTextSec, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(e.result,
                                          style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: _clearHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAcento,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Limpiar historial'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingTab extends StatefulWidget {
  final TabController controller;
  const _PulsingTab({required this.controller});

  @override
  State<_PulsingTab> createState() => _PulsingTabState();
}

class _PulsingTabState extends State<_PulsingTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _on = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted) setState(() => _on = !_on);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: _on ? kAcento : const Color(0xFF333333),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.print, color: kAcento, size: 16),
          const SizedBox(width: 4),
          Text(
            'Impresión',
            style: TextStyle(
              color: kAcento,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flecha indicadora de scroll que rebota
class _BounceArrow extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _BounceArrow({required this.icon, required this.color});

  @override
  State<_BounceArrow> createState() => _BounceArrowState();
}

class _BounceArrowState extends State<_BounceArrow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _ctrl.value * 5),
        child: child,
      ),
      child: Icon(widget.icon, color: widget.color, size: 22),
    );
  }
}

/// Boton Recientes con fondo visible al pasar el mouse
class _RecientesButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RecientesButton({required this.onTap});

  @override
  State<_RecientesButton> createState() => _RecientesButtonState();
}

class _RecientesButtonState extends State<_RecientesButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: _hover ? kNumHover : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Icon(Symbols.history, color: kText, size: 22),
        ),
      ),
    );
  }
}

/// Entrada del historial (expresion + resultado)
class _HistEntry {
  final String expr;
  final String result;
  _HistEntry(this.expr, this.result);
}

// ===================== Calculadora =====================
class CalculatorPage extends StatefulWidget {
  final VoidCallback onRecientes;
  final void Function(String expr, String result) onAddHistory;
  const CalculatorPage({
    super.key,
    required this.onRecientes,
    required this.onAddHistory,
  });
  @override
  State<CalculatorPage> createState() => CalculatorPageState();
}

class CalculatorPageState extends State<CalculatorPage> {
  final FocusNode _focusNode = FocusNode();
  String raw = '0';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }
  double primerValor = 0;
  String operacion = '';
  bool nuevoNumero = true;
  bool errorState = false;
  bool expuesto = false;
  String ultimoOp = '';
  double ultimoValor = 0;

  String expresion = ' ';

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Pone un resultado del historial en la pantalla de la calculadora
  void setValorDesdeHistorial(String valor) {
    if (valor.isEmpty) return;
    setState(() {
      raw = valor;
      nuevoNumero = true;
      errorState = false;
      expresion = ' ';
      operacion = '';
      primerValor = 0;
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    String? token;
    // Caracteres imprimibles
    final ch = event.character;
    if (ch != null && ch.isNotEmpty) {
      if (RegExp(r'^[0-9]$').hasMatch(ch)) {
        token = ch;
      } else {
        switch (ch) {
          case '.':
          case ',':
            token = '.';
            break;
          case '+':
            token = '+';
            break;
          case '-':
            token = '-';
            break;
          case '*':
            token = '*';
            break;
          case '/':
            token = '/';
            break;
          case '%':
            token = '%';
            break;
          case '=':
            token = '=';
            break;
        }
      }
    }
    // Teclas especiales / numpad
    final key = event.logicalKey;
    if (token == null) {
      if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) token = '0';
      else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) token = '1';
      else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) token = '2';
      else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) token = '3';
      else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) token = '4';
      else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) token = '5';
      else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) token = '6';
      else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) token = '7';
      else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) token = '8';
      else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) token = '9';
      else if (key == LogicalKeyboardKey.numpadAdd) token = '+';
      else if (key == LogicalKeyboardKey.numpadSubtract) token = '-';
      else if (key == LogicalKeyboardKey.numpadMultiply) token = '*';
      else if (key == LogicalKeyboardKey.numpadDivide) token = '/';
      else if (key == LogicalKeyboardKey.numpadDecimal) token = '.';
      else if (key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.enter) token = '=';
      else if (key == LogicalKeyboardKey.escape) token = 'C';
      else if (key == LogicalKeyboardKey.backspace) token = '⌫';
      else if (key == LogicalKeyboardKey.delete) token = 'CE';
    }
    if (token != null) {
      manejarIngreso(token);
    }
  }

  void manejarIngreso(String token) {
    // Operadores
    switch (token) {
      case '+':
        presionarOperador('+');
        return;
      case '-':
      case '−':
        presionarOperador('-');
        return;
      case '*':
      case '×':
        presionarOperador('*');
        return;
      case '/':
      case '÷':
        presionarOperador('/');
        return;
    }

    switch (token) {
      case 'C':
        raw = '0';
        primerValor = 0;
        operacion = '';
        nuevoNumero = true;
        errorState = false;
        expuesto = false;
        expresion = ' ';
        setState(() {});
        break;
      case 'CE':
        if (errorState) {
          manejarIngreso('C');
          return;
        }
        raw = '0';
        nuevoNumero = true;
        setState(() {});
        break;
      case '⌫':
        if (errorState) return;
        if (nuevoNumero && operacion.isNotEmpty) {
          operacion = '';
          expresion = ' ';
          setState(() {});
          return;
        }
        if (raw.length <= 1 || raw == '-') {
          raw = '0';
          nuevoNumero = true;
        } else {
          raw = raw.substring(0, raw.length - 1);
          if (raw == '-' || raw.isEmpty) {
            raw = '0';
            nuevoNumero = true;
          }
        }
        setState(() {});
        break;
      case '±':
        if (errorState) return;
        if (raw == '0') return;
        raw = raw.startsWith('-') ? raw.substring(1) : '-$raw';
        if (!nuevoNumero) expresion = ' ';
        setState(() {});
        break;
      case '%':
        aplicarPorcentaje();
        break;
      case '1/x':
        aplicarUnaria('1/x');
        break;
      case 'x²':
        aplicarUnaria('x²');
        break;
      case '√x':
        aplicarUnaria('√x');
        break;
      case '=':
        calcular();
        break;
      case '.':
        if (errorState) manejarIngreso('C');
        if (nuevoNumero) {
          raw = '0.';
          nuevoNumero = false;
        } else if (!raw.contains('.')) {
          raw += '.';
        }
        setState(() {});
        break;
      default:
        if (!RegExp(r'^[0-9]$').hasMatch(token)) return;
        if (errorState) {
          errorState = false;
          raw = '';
        }
        if (nuevoNumero) {
          raw = token;
          nuevoNumero = false;
          if (operacion.isEmpty) {
            expresion = ' ';
            expuesto = false;
          }
        } else {
          final sinSigno = raw.startsWith('-') ? raw.substring(1) : raw;
          final significativos = sinSigno.replaceAll('.', '').length;
          if (significativos >= 16) return;
          if (raw == '0') {
            raw = token;
          } else if (raw == '-0') {
            raw = '-$token';
          } else {
            raw += token;
          }
        }
        setState(() {});
        break;
    }
  }

  void presionarOperador(String op) {
    if (errorState) return;
    try {
      final actual = double.parse(raw);
      if (operacion.isEmpty) {
        primerValor = actual;
      } else if (!nuevoNumero) {
        final r = evalu(primerValor, actual, operacion);
        if (r.isNaN || r.isInfinite) {
          mostrarError();
          return;
        }
        primerValor = r;
        raw = aTexto(primerValor);
      }
      operacion = op;
      nuevoNumero = true;
      refrescarExpresion(null);
      setState(() {});
    } catch (_) {}
  }

  void aplicarPorcentaje() {
    if (errorState) return;
    try {
      final v = double.parse(raw);
      double r;
      if (operacion == '+' || operacion == '-') {
        r = primerValor * v / 100.0;
      } else {
        r = v / 100.0;
      }
      raw = aTexto(r);
      nuevoNumero = false;
      setState(() {});
    } catch (_) {}
  }

  void aplicarUnaria(String tipo) {
    if (errorState) return;
    try {
      final v = double.parse(raw);
      double r;
      String anotacion;
      switch (tipo) {
        case '√x':
          if (v < 0) {
            mostrarError();
            return;
          }
          r = math.sqrt(v);
          anotacion = '√(${grupo(aTexto(v))})';
          break;
        case 'x²':
          r = v * v;
          anotacion = 'sqr(${grupo(aTexto(v))})';
          break;
        default:
          if (v == 0) {
            mostrarError();
            return;
          }
          r = 1.0 / v;
          anotacion = '1/(${grupo(aTexto(v))})';
          break;
      }
      raw = aTexto(r);
      nuevoNumero = false;
      setState(() {});
      if (operacion.isEmpty) {
        expresion = anotacion;
      } else {
        refrescarExpresion(anotacion);
      }
      setState(() {});
    } catch (_) {}
  }

  void calcular() {
    if (errorState) return;
    try {
      final segundo = double.parse(raw);
      double r;
      String expTxt;
      if (operacion.isNotEmpty) {
        r = evalu(primerValor, segundo, operacion);
        expTxt = '${grupo(aTexto(primerValor))} ${simbodo(operacion)} ${grupo(aTexto(segundo))} =';
        ultimoOp = operacion;
        ultimoValor = segundo;
        operacion = '';
        primerValor = 0;
        expuesto = true;
      } else if (ultimoOp.isNotEmpty) {
        r = evalu(segundo, ultimoValor, ultimoOp);
        expTxt = '${grupo(aTexto(segundo))} ${simbodo(ultimoOp)} ${grupo(aTexto(ultimoValor))} =';
        expuesto = true;
      } else {
        expresion = ' ';
        expuesto = false;
        setState(() {});
        return;
      }
      if (r.isNaN || r.isInfinite) {
        mostrarError();
        return;
      }
      nuevoNumero = true;
      raw = aTexto(r);
      expresion = expTxt;
      widget.onAddHistory(expTxt, raw);
      setState(() {});
    } catch (_) {
      mostrarError();
    }
  }

  void mostrarError() {
    errorState = true;
    operacion = '';
    primerValor = 0;
    nuevoNumero = true;
    expresion = ' ';
    raw = 'No se puede dividir entre cero';
    setState(() {});
  }

  double evalu(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        return b == 0 ? double.nan : a / b;
    }
    return b;
  }

  void refrescarExpresion(String? extra) {
    if (operacion.isEmpty) {
      expresion = extra ?? ' ';
    } else {
      final base = '${grupo(aTexto(primerValor))} ${simbodo(operacion)}';
      expresion = extra == null ? base : '$base $extra';
    }
    setState(() {});
  }

  String simbodo(String op) {
    switch (op) {
      case '*':
        return '×';
      case '/':
        return '÷';
      case '-':
        return '−';
      default:
        return '+';
    }
  }

  String aTexto(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    if (v.abs() < 1e15 && v == v.floor()) return v.toInt().toString();
    String s = v.toString();
    if (s.length > 14) {
      s = v.toStringAsFixed(10).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  String grupo(String s) {
    if (s == 'Error') return s;
    bool neg = s.startsWith('-');
    if (neg) s = s.substring(1);
    final parts = s.split('.');
    final ip = StringBuffer();
    for (int i = 0; i < parts[0].length; i++) {
      if (i > 0 && (parts[0].length - i) % 3 == 0) ip.write(',');
      ip.write(parts[0][i]);
    }
    String res = ip.isEmpty ? '0' : ip.toString();
    if (parts.length == 2) res += '.${parts[1]}';
    return (neg ? '-' : '') + res;
  }


  @override
  Widget build(BuildContext context) {
    final displayText = errorState ? raw : grupo(raw);
    final fontSize = displayText.length > 16
        ? 22.0
        : displayText.length > 12
            ? 28.0
            : 38.0;

    final rows = <List<String>>[
      ['%', 'CE', 'C', '⌫'],
      ['1/x', 'x²', '√x', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Container(
        color: kCalcBg,
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
        child: Column(
        children: [
          // Display (altura fija) + botón Recientes a la izquierda
          Container(
            color: kCalcBg,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: SizedBox(
              height: 76,
              child: Row(
                children: [
                  // Botón Recientes
                  InkWell(
                    onTap: widget.onRecientes,
                    hoverColor: kFnHover,
                    borderRadius: BorderRadius.circular(4),
                    child: _RecientesButton(onTap: widget.onRecientes),
                  ),
                  // Display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 22,
                          child: Text(
                            expresion,
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: kTextSec, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: displayText)
                              ..selection = TextSelection.collapsed(offset: displayText.length),
                            readOnly: true,
                            textAlign: TextAlign.right,
                            style: TextStyle(color: kText, fontSize: fontSize),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              filled: true,
                              fillColor: kCalcBg,
                              hoverColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Teclado
          Expanded(
            child: Column(
              children: [
                for (final row in rows)
                  Expanded(
                    child: Row(
                      children: [
                        for (final t in row)
                          Expanded(child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: _buildButton(t),
                          )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  IconData? _iconoPara(String texto) {
    switch (texto) {
      case '⌫':
        return Icons.backspace_outlined;
      default:
        return null;
    }
  }

  Widget _buildButton(String texto) {
    Color bg;
    Color hoverBg;
    Color fg;
    double size;
    FontWeight weight = FontWeight.normal;
    String font = 'Roboto';

    if (texto == '=') {
      bg = kEqualsBg;
      hoverBg = kEqualsHover;
      fg = Colors.black;
      size = 18;
      weight = FontWeight.bold;
    } else if (texto == '÷' || texto == '×' || texto == '−' || texto == '+') {
      bg = kFnBg;
      hoverBg = kFnHover;
      fg = kText;
      size = 26;
    } else if (texto == '%' ||
        texto == 'CE' ||
        texto == 'C' ||
        texto == '⌫' ||
        texto == '1/x' ||
        texto == 'x²' ||
        texto == '√x') {
      bg = kFnBg;
      hoverBg = kFnHover;
      fg = kText;
      size = texto == '⌫' ? 18 : 19;
      if (texto == '⌫') {
        bg = const Color(0xFF4A4A4A);
      }
    } else {
      bg = kNumBg;
      hoverBg = kNumHover;
      fg = kText;
      size = 23;
    }

    return _CalcButton(
      label: texto,
      icon: _iconoPara(texto),
      bg: bg,
      hoverBg: hoverBg,
      fg: fg,
      fontSize: size,
      fontWeight: weight,
      fontFamily: font,
      onTap: () => manejarIngreso(texto),
    );
  }
}

class _CalcButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color bg;
  final Color hoverBg;
  final Color fg;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;
  final VoidCallback onTap;

  const _CalcButton({
    required this.label,
    this.icon,
    required this.bg,
    required this.hoverBg,
    required this.fg,
    required this.fontSize,
    required this.fontWeight,
    required this.fontFamily,
    required this.onTap,
  });

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton> {
  bool _pressed = false;
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: _pressed
                ? widget.bg.withValues(alpha: 0.7)
                : (_hovering ? widget.hoverBg : widget.bg),
            borderRadius: BorderRadius.circular(4),
          ),
        alignment: Alignment.center,
        child: widget.icon != null
            ? Icon(widget.icon, color: widget.fg, size: 18)
            : Text(
                widget.label,
                style: TextStyle(
                  color: widget.fg,
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  fontFamily: widget.fontFamily,
                  fontFamilyFallback: const ['Segoe UI Symbol', 'Segoe UI'],
                ),
              ),
      ),
    ),
    );
  }
}

// ===================== Impresión =====================
class PrintingPage extends StatefulWidget {
  const PrintingPage({super.key});
  @override
  State<PrintingPage> createState() => PrintingPageState();
}

class PrintingPageState extends State<PrintingPage> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _puedeBajar = false;
  bool _puedeSubir = false;

  final TextEditingController txtColor = TextEditingController();
  final TextEditingController txtBN = TextEditingController();
  final TextEditingController txtPrecioEmp = TextEditingController(text: '250');
  bool chkEmp = false;

  String lblSubColor = 'Subtotal color: \$0.00';
  String lblSubBN = 'Subtotal B/N: \$0.00';
  String lblSubEmp = 'Subtotal empastado: \$0.00';
  String lblTotal = '\$0.00';
  String lblDesglose = 'Ingresa cantidades para ver el desglose';

  @override
  void initState() {
    super.initState();
    txtColor.addListener(_calc);
    txtBN.addListener(_calc);
    txtPrecioEmp.addListener(_calc);
    _scrollCtrl.addListener(_actualizarFlechas);
    WidgetsBinding.instance.addPostFrameCallback((_) => _actualizarFlechas());
  }

  void _actualizarFlechas() {
    if (!mounted) return;
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    final puedeBajar = pos.maxScrollExtent > pos.pixels + 2;
    final puedeSubir = pos.pixels > 2;
    if (puedeBajar != _puedeBajar || puedeSubir != _puedeSubir) {
      setState(() {
        _puedeBajar = puedeBajar;
        _puedeSubir = puedeSubir;
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    txtColor.dispose();
    txtBN.dispose();
    txtPrecioEmp.dispose();
    super.dispose();
  }

  void resetear() {
    setState(() {
      chkEmp = false;
      txtColor.text = '';
      txtBN.text = '';
      txtPrecioEmp.text = '250';
    });
    _calc();
  }

  void _calc() {
    int cColor = 0, cBN = 0;
    bool err = false;
    final tc = txtColor.text.trim();
    if (tc.isNotEmpty) {
      try { cColor = parsear(tc); } catch (_) { err = true; }
    }
    final tb = txtBN.text.trim();
    if (tb.isNotEmpty) {
      try { cBN = parsear(tb); } catch (_) { err = true; }
    }
    double subColor = cColor * 15.0;
    double subBN = cBN * 3.0;
    double subEmp = 0;
    if (chkEmp) {
      final tp = txtPrecioEmp.text.trim();
      if (tp.isNotEmpty) {
        try { subEmp = double.parse(tp); } catch (_) { err = true; }
      }
    }
    if (err) {
      setState(() {
        lblTotal = '\$0.00';
        lblDesglose = 'Formato no valido. Revisa los campos.';
        lblSubColor = 'Subtotal color: \$0.00';
        lblSubBN = 'Subtotal B/N: \$0.00';
        lblSubEmp = 'Subtotal empastado: \$0.00';
      });
      return;
    }
    if (cColor > 100000 || cBN > 100000) {
      setState(() {
        lblTotal = '\$0.00';
        lblDesglose = 'Cantidad muy grande.';
      });
      return;
    }
    final total = subColor + subBN + subEmp;
    final sb = StringBuffer();
    if (cColor > 0) sb.write('$cColor color');
    if (cBN > 0) { if (sb.isNotEmpty) sb.write('  .  '); sb.write('$cBN B/N'); }
    if (chkEmp) { if (sb.isNotEmpty) sb.write('  .  '); sb.write('empastado ${subEmp.toStringAsFixed(2)}'); }
    if (sb.isEmpty) sb.write('Ingresa cantidades para ver el desglose');
    setState(() {
      lblTotal = '\$${total.toStringAsFixed(2)}';
      lblSubColor = 'Subtotal color: \$${subColor.toStringAsFixed(2)}  ($cColor hoja(s) x \$15)';
      lblSubBN = 'Subtotal B/N: \$${subBN.toStringAsFixed(2)}  ($cBN hoja(s) x \$3)';
      lblSubEmp = 'Subtotal empastado: \$${subEmp.toStringAsFixed(2)}';
      lblDesglose = sb.toString();
    });
  }

  int parsear(String t) {
    t = t.trim();
    if (t.isEmpty) return 0;
    if (!t.contains(',') && !t.contains('-')) {
      final n = int.parse(t);
      if (n < 0) throw FormatException();
      return n;
    }
    int total = 0;
    for (final tk in t.split(',')) {
      final trimmed = tk.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.contains('-')) {
        final p = trimmed.split('-');
        if (p.length != 2) throw FormatException();
        final a = int.parse(p[0].trim());
        final b = int.parse(p[1].trim());
        total += (b - a).abs() + 1;
      } else {
        total += 1;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF202020),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(8, 8, 25, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Hojas a color',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Hojas / paginas:',
                      style: TextStyle(color: Color(0xFFE8E8E8), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _input(txtColor, 'Ingrese la cantidad de hojas', formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\-]'))]),
                  const SizedBox(height: 4),
                  const Text('Formato estilo Word: 12 o 2,20-20,2. Precio por hoja: \$15.',
                      style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(lblSubColor, style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Hojas en blanco y negro',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Hojas / paginas:',
                      style: TextStyle(color: Color(0xFFE8E8E8), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _input(txtBN, 'Ingrese la cantidad de hojas', formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\-]'))]),
                  const SizedBox(height: 4),
                  const Text('Formato estilo Word: 12 o 2,20-20,2. Precio por hoja: \$3.',
                      style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(lblSubBN, style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Empastado',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Checkbox(
                        value: chkEmp,
                        activeColor: kAcento,
                        onChanged: (v) {
                          setState(() {
                            chkEmp = v ?? false;
                            if (chkEmp) {
                              if (txtPrecioEmp.text.trim().isEmpty) txtPrecioEmp.text = '250';
                            } else {
                              txtPrecioEmp.text = '250';
                            }
                          });
                          _calc();
                        },
                      ),
                      const Expanded(
                        child: Text('Marcar esta casilla si se realizo el empastado',
                            style: TextStyle(color: Color(0xFFE8E8E8), fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Precio del empastado:',
                      style: TextStyle(color: Color(0xFFE8E8E8), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _input(txtPrecioEmp, 'Ingrese el precio del empastado', enabled: chkEmp, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
                  const SizedBox(height: 4),
                  const Text('Activa la casilla y ajusta el precio (por defecto \$250).',
                      style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(lblSubEmp, style: const TextStyle(color: Color(0xFFE8E8E8), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('TOTAL A PAGAR',
                      style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(lblTotal,
                      style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 34,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(lblDesglose,
                      style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
          // Indicador de scroll hacia abajo (sobre el scrollbar)
          Positioned(
            right: 0,
            bottom: 2,
            child: AnimatedOpacity(
              opacity: _puedeBajar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const _BounceArrow(icon: Icons.keyboard_arrow_down, color: Color(0xFFF59E0B)),
            ),
          ),
          // Indicador de scroll hacia arriba (sobre el scrollbar)
          Positioned(
            right: 0,
            top: 2,
            child: AnimatedOpacity(
              opacity: _puedeSubir ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const _BounceArrow(icon: Icons.keyboard_arrow_up, color: Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border.all(color: const Color(0xFF444444), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  Widget _input(TextEditingController c, String hint, {bool enabled = true, List<TextInputFormatter>? formatters}) {
    final ts = MediaQuery.textScaleFactorOf(context);
    return SizedBox(
      height: 34 * ts,
      child: TextField(
        controller: c,
        enabled: enabled,
        inputFormatters: formatters,
        style: TextStyle(
          color: enabled ? const Color(0xFFE8E8E8) : const Color(0xFF808080),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF808080), fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF333333),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF444444)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF444444)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFF59E0B)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF444444)),
          ),
        ),
      ),
    );
  }
}

// ===================== helpers =====================
int parsear(String t) {
  t = t.trim();
  if (t.isEmpty) return 0;
  if (!t.contains(',') && !t.contains('-')) {
    final n = int.parse(t);
    if (n < 0) throw FormatException();
    return n;
  }
  int total = 0;
  for (final tk in t.split(',')) {
    final trimmed = tk.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.contains('-')) {
      final p = trimmed.split('-');
      if (p.length != 2) throw FormatException();
      final a = int.parse(p[0].trim());
      final b = int.parse(p[1].trim());
      total += (b - a).abs() + 1;
    } else {
      total += 1;
    }
  }
  return total;
}
