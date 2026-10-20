# J&L Calc (Flutter Desktop)

Calculadora y presupuesto de impresión para Windows, escrita en **Flutter** (escritorio).

🔗 https://github.com/sebac15062008/J-L-Calc-Flutter

## Funcionalidades

### Pestaña Calculadora
- Estilo **Windows Calculator** (tema oscuro, misma paleta de microsoft/calculator).
- Símbolos reales: `× ÷ −` y `⌫` con iconos **Google Material Symbols**.
- `%` contextual (200 + 10 % = 220), `=` repetido, separador de miles (1,234.56).
- Mensaje de error: *No se puede dividir entre cero*.
- **Teclado físico completo**: dígitos, numpad, operadores, `Enter`, `Backspace`, `Delete`, `Esc`, `%`, `.`.
- Botón **Recientes** (icono `history`) que abre una **barra lateral** con el historial:
  - Expresión arriba y resultado abajo, al estilo de Microsoft Calculator.
  - Al hacer clic en un resultado, se coloca en la calculadora.
  - Se guarda de forma persistente en `%USERPROFILE%\.jlcalc_history.txt` y solo se borra con **Limpiar historial**.

### Pestaña Impresión
- Tres bloques independientes, cada uno con su campo de hojas/páginas:
  1. **Hojas a color** — $15 por hoja
  2. **Hojas en blanco y negro** — $3 por hoja
  3. **Empastado** — casilla "Marcar esta casilla si se realizo el empastado" + precio editable (por defecto $250)
- Cálculo **en vivo** mientras se escribe.
- Formato estilo Word: `12` o `2,20-20,2` (rangos con guion y comas).
- Scrollbar siempre visible con flechas indicadoras (subir/bajar) dentro de la pista.
- Total a pagar a ancho completo.

## Requisitos
- Flutter 3.47 o superior (Dart 3.13)
- Windows 10/11 x64 con **Desktop development for Windows**

## Compilar y ejecutar

```bash
flutter pub get
flutter run -d windows
```

## Generar el instalador (Inno Setup)

```bash
flutter build windows
# luego compilar el script con Inno Setup 6
ISCC.exe setup.iss
```

El instalador queda en `J&L Calc Setup.exe` e instala en
`C:\Program Files (x86)\J&L Calc`.

## Estructura

```
lib/main.dart            Toda la aplicación (calculadora + impresión + historial)
assets/logo.png          Logo del encabezado
assets/fonts/            Fuente Material Icons completa
windows/runner/          Runner nativo de Windows (icono, tamaño de ventana, bloqueo de maximizar)
setup.iss                Script de Inno Setup para el instalador
```

## Notas
- La ventana es de **384×720 px**, se puede redimensionar solo en vertical
  (ancho fijo) y con **tamaño mínimo 600 px** de alto.
- Sin botón de maximizar.
