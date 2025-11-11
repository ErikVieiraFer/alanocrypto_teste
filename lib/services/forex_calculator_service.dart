class ForexCalculatorService {
  static const double standardLotSize = 100000;

  static double calculatePipValue(String pair, double price) {
    if (pair.endsWith('/USD')) {
      return (0.0001 / price) * standardLotSize;
    } else if (pair.startsWith('USD/')) {
      return 0.0001 * standardLotSize;
    } else if (pair.endsWith('/JPY')) {
      return (0.01 / price) * standardLotSize;
    } else {
      return 0.0001 * standardLotSize;
    }
  }

  static Map<String, dynamic> calculate({
    required String pair,
    required double currentPrice,
    required double accountBalance,
    required double riskPercentage,
    required double stopPips,
    required int leverage,
  }) {
    final pipValue = calculatePipValue(pair, currentPrice);
    final riskDollar = accountBalance * (riskPercentage / 100);
    final positionSizeLots = riskDollar / (stopPips * pipValue);
    final positionSizeUnits = positionSizeLots * standardLotSize;
    final marginRequired = (positionSizeUnits * currentPrice) / leverage;
    final riskRewardRatio = riskDollar > 0 ? (positionSizeLots * pipValue * stopPips) / riskDollar : 0;

    return {
      'positionSizeLots': positionSizeLots,
      'positionSizeUnits': positionSizeUnits,
      'pipValue': pipValue,
      'riskDollar': riskDollar,
      'marginRequired': marginRequired,
      'riskRewardRatio': riskRewardRatio,
    };
  }
}
