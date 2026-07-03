class PriceUtils {
  /// يحسب متوسط السعر العادل مع استبعاد القيم الشاذة (Outliers) مثل أسعار المخربين.
  /// يستخدم طريقة المدى الربيعي (IQR) لاستبعاد القيم العالية جداً أو المنخفضة جداً.
  static double? calculateFairAverage(List<double> prices) {
    if (prices.isEmpty) return null;
    if (prices.length == 1) return prices.first;
    
    // ترتيب الأسعار تصاعدياً
    final sorted = List<double>.from(prices)..sort();
    
    // 1. حساب الوسيط (Median)
    double median;
    int middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      median = sorted[middle];
    } else {
      median = (sorted[middle - 1] + sorted[middle]) / 2.0;
    }

    if (median == 0) {
      return sorted.reduce((a, b) => a + b) / sorted.length;
    }

    // 2. تصفية الأسعار الخيالية
    // نعتبر أي سعر أكبر من 4 أضعاف الوسيط سعراً خيالياً (مخرب)
    // وأي سعر أقل من ربع الوسيط قد يكون غير منطقي
    final double maxAllowed = median * 4;
    final double minAllowed = median / 4;
    
    final validPrices = sorted.where((p) => p <= maxAllowed && p >= minAllowed).toList();
    
    // إذا تم استبعاد كل القيم، نرجع الوسيط كأفضل تقدير عادل
    if (validPrices.isEmpty) {
      return median;
    }
    
    // إرجاع متوسط القيم المقبولة
    return validPrices.reduce((a, b) => a + b) / validPrices.length;
  }
}
