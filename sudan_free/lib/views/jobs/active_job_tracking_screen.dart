import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../../services/smart_guide_service.dart';
import '../../widgets/reviews/review_widgets.dart';
import '../../models/review_model.dart';
import '../../services/firestore_service.dart';

class ActiveJobTrackingScreen extends StatefulWidget {
  final String jobId;

  const ActiveJobTrackingScreen({super.key, required this.jobId});

  @override
  State<ActiveJobTrackingScreen> createState() => _ActiveJobTrackingScreenState();
}

class _ActiveJobTrackingScreenState extends State<ActiveJobTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchJob(widget.jobId);
      
      SmartGuideService.showMicroTip(
        context,
        messageAr: 'يمكنك تقسيم الدفعات حسب مراحل الإنجاز 📊',
        messageEn: 'You can split payments based on milestones 📊',
        tipId: 'job_tracking_tip',
        icon: Icons.pie_chart_rounded,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final authProvider = context.watch<AuthProvider>();
    final job = jobProvider.selectedJob;
    final currentUser = authProvider.user;

    if (jobProvider.isLoading || job == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final isClient = currentUser?.id == job.clientId;
    final isFreelancer = currentUser?.id == job.assignedFreelancerId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('إدارة الاتفاق', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isClient && job.status == JobStatus.inProgress)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showCompleteDialog(context, job),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('إكمال الاتفاق'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobHeader(job, isDark),
            const SizedBox(height: 24),
            _buildStatusCard(job, isDark),
            const SizedBox(height: 24),
            _buildStepper(job, isDark),
            const SizedBox(height: 24),
            
            // Progress Section
            if (job.milestones.isNotEmpty)
              _buildProgressSection(job),
              
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('دفعات الإنجاز (Milestones)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (isClient && job.status == JobStatus.inProgress)
                  TextButton.icon(
                    onPressed: () => _showAddMilestoneSheet(context, job),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('إضافة'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (job.milestones.isEmpty)
               _buildEmptyMilestones(context, job, isClient, isDark)
            else
              ...job.milestones.map((m) => _buildMilestoneTile(context, job, m, isClient, isFreelancer, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHeader(JobModel job, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handshake, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الطرف الآخر: ${job.assignedFreelancerName ?? job.clientName}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderStat(Icons.payments, '${NumberFormat('#,##0').format(job.budgetMax)} SDG', 'الميزانية'),
              Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 16)),
              _buildHeaderStat(Icons.calendar_today, DateFormat('dd MMM yyyy').format(job.createdAt), 'تاريخ البدء'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(JobModel job, bool isDark) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (job.status) {
      case JobStatus.inProgress:
        statusColor = Colors.blue;
        statusText = 'قيد التنفيذ';
        statusIcon = Icons.autorenew;
        break;
      case JobStatus.completed:
        statusColor = Colors.green;
        statusText = 'مكتمل';
        statusIcon = Icons.check_circle;
        break;
      case JobStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'ملغي';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'مفتوح';
        statusIcon = Icons.lock_open;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('حالة الاتفاق', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(JobModel job, bool isDark) {
    if (job.status == JobStatus.cancelled) return const SizedBox.shrink();

    int currentStep = 0;
    if (job.status == JobStatus.inProgress) {
      if (job.milestones.isNotEmpty && job.milestones.any((m) => m.isCompleted)) {
        currentStep = 2; // Some progress made
      } else {
        currentStep = 1; // Just started
      }
    } else if (job.status == JobStatus.completed) {
      currentStep = 3;
    }

    final steps = [
      {'title': 'مفتوح', 'icon': Icons.assignment},
      {'title': 'قيد التنفيذ', 'icon': Icons.play_circle_fill},
      {'title': 'مرحلي', 'icon': Icons.hourglass_bottom},
      {'title': 'مكتمل', 'icon': Icons.check_circle},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مسار الاتفاق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index % 2 != 0) {
                // Line
                final stepIndex = index ~/ 2;
                final isPassed = stepIndex < currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isPassed ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                  ),
                );
              }
              // Circle
              final stepIndex = index ~/ 2;
              final isActive = stepIndex == currentStep;
              final isPassed = stepIndex < currentStep;
              final color = isPassed || isActive ? AppColors.primary : Colors.grey.withValues(alpha: 0.3);
              
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive ? color.withValues(alpha: 0.2) : color,
                      shape: BoxShape.circle,
                      border: isActive ? Border.all(color: color, width: 2) : null,
                    ),
                    child: Icon(
                      steps[stepIndex]['icon'] as IconData, 
                      size: 16, 
                      color: isActive ? color : Colors.white
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[stepIndex]['title'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive || isPassed ? FontWeight.bold : FontWeight.normal,
                      color: isActive || isPassed ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressSection(JobModel job) {
    final totalMilestones = job.milestones.length;
    final completedMilestones = job.milestones.where((m) => m.isCompleted).length;
    final progress = totalMilestones == 0 ? 0.0 : completedMilestones / totalMilestones;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('نسبة الإنجاز', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text('$completedMilestones من أصل $totalMilestones مراحل مكتملة', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyMilestones(BuildContext context, JobModel job, bool isClient, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          const Text('لا توجد دفعات محددة بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'قم بتحديد دفعات الإنجاز لتسهيل عملية الدفع وتقسيم العمل على مراحل مريحة للطرفين.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (isClient && job.status == JobStatus.inProgress) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddMilestoneSheet(context, job),
              icon: const Icon(Icons.add),
              label: const Text('تحديد دفعة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestoneTile(BuildContext context, JobModel job, MilestoneModel m, bool isClient, bool isFreelancer, bool isDark) {
    final bool canComplete = isFreelancer && job.status == JobStatus.inProgress;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isPaid ? Colors.green.withValues(alpha: 0.5) : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          width: m.isPaid ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: m.isCompleted,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: canComplete ? (val) => _toggleMilestoneCompletion(job, m, val!) : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      decoration: m.isCompleted ? TextDecoration.lineThrough : null,
                      color: m.isCompleted ? Colors.grey : null,
                    )
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${NumberFormat('#,##0').format(m.amount)} ${job.currency}', 
                      style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13)
                    ),
                  ),
                ],
              ),
            ),
            if (m.isPaid && m.isConfirmed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text('مكتملة ومدفوعة', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              )
            else if (m.isCompleted)
              ElevatedButton(
                onPressed: () => _confirmPaymentReceived(job, m),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('تأكيد الدفع', style: TextStyle(fontSize: 13)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text('قيد العمل', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneSheet(BuildContext context, JobModel job) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double currentTotal = job.milestones.fold(0.0, (acc, m) => acc + m.amount);
    final double remainingAmount = job.budgetMax - currentTotal;

    if (remainingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تقسيم كامل المبلغ المتفق عليه بالفعل.'), backgroundColor: Colors.orange),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_task, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text('إضافة دفعة إنجاز جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('المبلغ المتبقي للتقسيم: ${NumberFormat('#,##0').format(remainingAmount)} ${job.currency}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: titleController, 
              decoration: InputDecoration(
                labelText: 'عنوان المرحلة (مثال: الدفعة الأولى)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
              )
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController, 
              decoration: InputDecoration(
                labelText: 'المبلغ (SDG)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
              ), 
              keyboardType: const TextInputType.numberWithOptions(decimal: true)
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty || amountController.text.trim().isEmpty) return;
                  
                  final newAmount = double.tryParse(amountController.text) ?? 0;
                  if (newAmount <= 0) return;
                  
                  if (newAmount > remainingAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('عذراً، المبلغ يتجاوز المتبقي من الميزانية (${NumberFormat('#,##0').format(remainingAmount)} ${job.currency})'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  final milestones = List<MilestoneModel>.from(job.milestones);
                  milestones.add(MilestoneModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    amount: newAmount,
                  ));
                  context.read<JobProvider>().updateMilestones(job.id, milestones);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إضافة الدفعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _toggleMilestoneCompletion(JobModel job, MilestoneModel m, bool completed) {
    final milestones = job.milestones.map((item) {
      if (item.id == m.id) {
        return MilestoneModel(
          id: item.id,
          title: item.title,
          amount: item.amount,
          isCompleted: completed,
          isPaid: item.isPaid,
          isConfirmed: item.isConfirmed,
          completedAt: completed ? DateTime.now() : null,
        );
      }
      return item;
    }).toList();
    context.read<JobProvider>().updateMilestones(job.id, milestones);

    if (completed) {
      _sendNotification(
        targetUserId: job.clientId,
        title: 'إنجاز مرحلة',
        message: 'تم إنجاز المرحلة: ${m.title}. يرجى مراجعتها والدفع.',
        jobId: job.id,
      );
    }
  }

  void _confirmPaymentReceived(JobModel job, MilestoneModel m) {
    final milestones = job.milestones.map((item) {
      if (item.id == m.id) {
        return MilestoneModel(
          id: item.id,
          title: item.title,
          amount: item.amount,
          isCompleted: item.isCompleted,
          isPaid: true,
          isConfirmed: true,
          completedAt: item.completedAt,
        );
      }
      return item;
    }).toList();
    context.read<JobProvider>().updateMilestones(job.id, milestones);

    _sendNotification(
      targetUserId: job.clientId,
      title: 'تم استلام الدفعة',
      message: 'قام مقدم الخدمة بتأكيد استلام الدفعة: ${m.title}.',
      jobId: job.id,
    );
  }

  void _showCompleteDialog(BuildContext context, JobModel job) {
    final double currentTotal = job.milestones.fold(0.0, (acc, m) => acc + m.amount);
    final bool isFullyFunded = currentTotal >= job.budgetMax;
    final bool isAllCompletedAndConfirmed = job.milestones.isNotEmpty && job.milestones.every((m) => m.isCompleted && m.isPaid && m.isConfirmed);

    if (!isFullyFunded || !isAllCompletedAndConfirmed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('لا يمكن إكمال الاتفاق'),
            ],
          ),
          content: const Text('لا يمكنك إنهاء هذا الاتفاق إلا بعد تقسيم كامل المبلغ المتفق عليه إلى دفعات، وإنجازها جميعاً، وتسديدها، ثم تأكيد مقدم الخدمة استلام جميع المبالغ.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('إكمال الاتفاق'),
          ],
        ),
        content: const Text('هل أنت متأكد أنك تريد تمييز هذا الاتفاق كمكتمل؟ سيؤدي ذلك إلى إنهاء العمل والسماح لكلا الطرفين بإضافة التقييمات.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              context.read<JobProvider>().completeJob(jobId: job.id, freelancerId: job.assignedFreelancerId!);
              
              if (job.assignedFreelancerId != null) {
                _sendNotification(
                  targetUserId: job.assignedFreelancerId!,
                  title: 'اكتمل الاتفاق',
                  message: 'تم إنهاء الاتفاق بنجاح! يمكنك الآن ترك تقييم.',
                  jobId: job.id,
                );
              }
              
              Navigator.pop(ctx);
              
              final authProvider = context.read<AuthProvider>();
              final currentUser = authProvider.user;
              if (currentUser?.id == job.clientId && job.assignedFreelancerId != null) {
                showDialog(
                  context: context,
                  builder: (_) => AddReviewDialog(
                    freelancerId: job.assignedFreelancerId!,
                    targetName: job.assignedFreelancerName ?? 'الحرفي',
                    jobId: job.id,
                    jobTitle: job.title,
                    onSubmit: (rating, comment, isNegative, isJobCompleted, wouldWorkAgain) async {
                      final review = ReviewModel(
                        id: '',
                        freelancerId: job.assignedFreelancerId!,
                        reviewerId: currentUser!.id,
                        reviewerName: currentUser.name,
                        reviewerImageUrl: currentUser.profileImageUrl,
                        rating: rating,
                        comment: comment,
                        isNegative: isNegative,
                        wouldWorkAgain: wouldWorkAgain,
                        jobId: job.id,
                        jobTitle: job.title,
                        createdAt: DateTime.now(),
                      );
                      
                      try {
                        await FirestoreService().createReview(review, isJobCompleted: isJobCompleted);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة التقييم بنجاح')));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إضافة التقييم')));
                      }
                    },
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('تأكيد الإكمال'),
          ),
        ],
      ),
    );
  }

  void _sendNotification({required String targetUserId, required String title, required String message, required String jobId}) {
    FirebaseFirestore.instance.collection('notifications').add({
      'userId': targetUserId,
      'type': NotificationType.system.name,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedId': jobId,
    });
  }
}
