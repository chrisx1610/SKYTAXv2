/// Pasos de la simulación de pago con tarjeta.
enum CardPaymentStep { validating, authorizing, approved }

/// Simulador de la pasarela de pagos.
///
/// Para efectos demostrativos no se conecta a ningún banco: reproduce los
/// tiempos y estados de una transacción real. Al integrar una pasarela
/// verdadera solo debe sustituirse esta clase.
class PaymentSimulator {
  const PaymentSimulator();

  /// Secuencia de validación → autorización → aprobación de una tarjeta.
  Stream<CardPaymentStep> processCard() async* {
    yield CardPaymentStep.validating;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    yield CardPaymentStep.authorizing;
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    yield CardPaymentStep.approved;
  }

  /// Verifica el número de referencia de un pago móvil.
  Future<bool> verifyMobileReference(String reference) async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final String digits = reference.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 6;
  }
}
