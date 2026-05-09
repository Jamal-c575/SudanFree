import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/review_model.dart';
import '../../providers/locale_provider.dart';
import '../../views/profile/profile_screen.dart';

class AddReviewDialog extends StatefulWidget {
  final String freelancerId;
  final String? jobId;
  final String? jobTitle;
  final Function(double rating, String comment, bool isNegative, bool isJobCompleted, bool? wouldWorkAgain) onSubmit;

  const AddReviewDialog({
    super.key,
    required this.freelancerId,
    this.jobId,
    this.jobTitle,
    required this.onSubmit,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  double _rating = 0;
  final bool _isNegative = false;
  bool _isJobCompleted = false;
  bool? _wouldWorkAgain; // سؤال الضمان الاجتماعي
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    return AlertDialog(
      title: Text(locale == 'ar' ? 'تقييم العمل' : 'Rate Work'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.jobTitle != null)
            Text(widget.jobTitle!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          
          // Star Rating
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingText(_rating, locale),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Comment
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: locale == 'ar' ? 'اكتب تعليقك (اختياري)' : 'Write a comment (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          
          // Job Completion Check
          CheckboxListTile(
            value: _isJobCompleted,
            onChanged: (v) => setState(() => _isJobCompleted = v ?? false),
            title: Text(
              locale == 'ar' ? 'هل أكمل الحرفي العمل بنجاح؟' : 'Did the freelancer complete the work?',
              style: const TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          
          const SizedBox(height: 8),
          
          // === سؤال الضمان الاجتماعي ===
          // سؤال مهم للسوق السوداني لبناء الثقة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sudanGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sudanGold.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.handshake, color: AppColors.sudanGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locale == 'ar' 
                            ? 'هل ستتعامل معه مرة أخرى؟' 
                            : 'Would you work with them again?',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _wouldWorkAgain = true),
                        icon: Icon(
                          _wouldWorkAgain == true ? Icons.check_circle : Icons.check_circle_outline,
                          color: _wouldWorkAgain == true ? Colors.green : Colors.grey,
                        ),
                        label: Text(
                          locale == 'ar' ? 'نعم، بالتأكيد' : 'Yes, definitely',
                          style: TextStyle(
                            color: _wouldWorkAgain == true ? Colors.green : Colors.grey[700],
                            fontWeight: _wouldWorkAgain == true ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _wouldWorkAgain == true ? Colors.green : Colors.grey[300]!,
                            width: _wouldWorkAgain == true ? 2 : 1,
                          ),
                          backgroundColor: _wouldWorkAgain == true ? Colors.green.withValues(alpha: 0.1) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _wouldWorkAgain = false),
                        icon: Icon(
                          _wouldWorkAgain == false ? Icons.cancel : Icons.cancel_outlined,
                          color: _wouldWorkAgain == false ? Colors.red : Colors.grey,
                        ),
                        label: Text(
                          locale == 'ar' ? 'لا أنصح' : 'No, I wouldn\'t',
                          style: TextStyle(
                            color: _wouldWorkAgain == false ? Colors.red : Colors.grey[700],
                            fontWeight: _wouldWorkAgain == false ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _wouldWorkAgain == false ? Colors.red : Colors.grey[300]!,
                            width: _wouldWorkAgain == false ? 2 : 1,
                          ),
                          backgroundColor: _wouldWorkAgain == false ? Colors.red.withValues(alpha: 0.1) : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating > 0
              ? () {
                  widget.onSubmit(_rating, _commentController.text.trim(), _isNegative, _isJobCompleted, _wouldWorkAgain);
                  Navigator.pop(context);
                }
              : null,
          child: Text(locale == 'ar' ? 'إرسال' : 'Submit'),
        ),
      ],
    );
  }

  String _getRatingText(double rating, String locale) {
    if (rating == 0) return locale == 'ar' ? 'اضغط لتقييم' : 'Tap to rate';
    if (rating <= 1) return locale == 'ar' ? 'سيء' : 'Poor';
    if (rating <= 2) return locale == 'ar' ? 'مقبول' : 'Fair';
    if (rating <= 3) return locale == 'ar' ? 'جيد' : 'Good';
    if (rating <= 4) return locale == 'ar' ? 'جيد جداً' : 'Very Good';
    return locale == 'ar' ? 'ممتاز' : 'Excellent';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// Review Card Widget
class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String locale;

  const ReviewCard({super.key, required this.review, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Color is automatically picked from CardTheme in AppTheme
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: review.reviewerId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: review.reviewerImageUrl != null
                        ? NetworkImage(review.reviewerImageUrl!)
                        : null,
                    child: review.reviewerImageUrl == null
                        ? Text(review.reviewerName[0].toUpperCase())
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.reviewerName,
                          style: Theme.of(context).textTheme.titleSmall),
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < review.rating.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          )),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(review.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review.comment!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (review.jobTitle != null && review.jobTitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${locale == 'ar' ? 'المشروع' : 'Project'}: ${review.jobTitle}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            
            // === مؤشر الضمان الاجتماعي ===
            if (review.wouldWorkAgain != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: review.wouldWorkAgain! 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: review.wouldWorkAgain! 
                        ? Colors.green.withValues(alpha: 0.3) 
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.wouldWorkAgain! ? Icons.thumb_up : Icons.thumb_down,
                      size: 14,
                      color: review.wouldWorkAgain! ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      review.wouldWorkAgain!
                          ? (locale == 'ar' ? 'سأتعامل معه مرة أخرى' : 'Would work again')
                          : (locale == 'ar' ? 'لا أنصح بالتعامل' : 'Would not recommend'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: review.wouldWorkAgain! ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
