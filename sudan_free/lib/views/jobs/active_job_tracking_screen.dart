import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/loading_widget.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع المشروع'),
        actions: [
          if (isClient && job.status == JobStatus.inProgress)
            TextButton(
              onPressed: () => _showCompleteDialog(context, job),
              child: const Text('إكمال المشروع', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobHeader(job),
            const SizedBox(height: 24),
            _buildStatusCard(job),
            const SizedBox(height: 24),
            const Text('مراحل التنفيذ (Milestones)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (job.milestones.isEmpty)
               _buildEmptyMilestones(context, job, isClient)
            else
              ...job.milestones.map((m) => _buildMilestoneTile(context, job, m, isClient, isFreelancer)),
            
            if (isClient && job.milestones.isNotEmpty && job.status == JobStatus.inProgress)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddMilestoneSheet(context, job),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة مرحلة جديدة'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHeader(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(job.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('مع ${job.assignedFreelancerName ?? job.clientName}', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatusCard(JobModel job) {
    Color statusColor;
    String statusText;

    switch (job.status) {
      case JobStatus.inProgress:
        statusColor = Colors.blue;
        statusText = 'قيد التنفيذ';
        break;
      case JobStatus.completed:
        statusColor = Colors.green;
        statusText = 'مكتمل';
        break;
      case JobStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'ملغي';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'مفتوح';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: statusColor),
          const SizedBox(width: 12),
          Text('حالة المشروع: $statusText', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyMilestones(BuildContext context, JobModel job, bool isClient) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.list_alt, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('لا توجد مراحل محددة بعد', style: TextStyle(color: Colors.grey)),
          if (isClient) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddMilestoneSheet(context, job),
              child: const Text('تحديد مراحل التنفيذ'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestoneTile(BuildContext context, JobModel job, MilestoneModel m, bool isClient, bool isFreelancer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: m.isCompleted,
          onChanged: (isFreelancer && job.status == JobStatus.inProgress) ? (val) => _toggleMilestoneCompletion(job, m, val!) : null,
        ),
        title: Text(m.title, style: TextStyle(decoration: m.isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Text('${m.amount} ${job.currency}'),
        trailing: m.isPaid 
            ? const Icon(Icons.check_circle, color: Colors.green)
            : (isClient && m.isCompleted && job.status == JobStatus.inProgress) 
                ? TextButton(onPressed: () => _payMilestone(job, m), child: const Text('دفع'))
                : const Icon(Icons.pending_actions, color: Colors.orange),
      ),
    );
  }

  void _showAddMilestoneSheet(BuildContext context, JobModel job) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إضافة مرحلة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان المرحلة')),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final milestones = List<MilestoneModel>.from(job.milestones);
                milestones.add(MilestoneModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  amount: double.parse(amountController.text),
                ));
                context.read<JobProvider>().updateMilestones(job.id, milestones);
                Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
            const SizedBox(height: 16),
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
          completedAt: completed ? DateTime.now() : null,
        );
      }
      return item;
    }).toList();
    context.read<JobProvider>().updateMilestones(job.id, milestones);
  }

  void _payMilestone(JobModel job, MilestoneModel m) {
    // Integrate with payment gateway later, for now just update status
    final milestones = job.milestones.map((item) {
      if (item.id == m.id) {
        return MilestoneModel(
          id: item.id,
          title: item.title,
          amount: item.amount,
          isCompleted: item.isCompleted,
          isPaid: true,
          completedAt: item.completedAt,
        );
      }
      return item;
    }).toList();
    context.read<JobProvider>().updateMilestones(job.id, milestones);
  }

  void _showCompleteDialog(BuildContext context, JobModel job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إكمال المشروع'),
        content: const Text('هل أنت متأكد أنك تريد تمييز هذا المشروع كمكتمل؟ سيتم إغلاق العقد.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              context.read<JobProvider>().completeJob(jobId: job.id, freelancerId: job.assignedFreelancerId!);
              Navigator.pop(ctx);
            },
            child: const Text('إكمال'),
          ),
        ],
      ),
    );
  }
}
