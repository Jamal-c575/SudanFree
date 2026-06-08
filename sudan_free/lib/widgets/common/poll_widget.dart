import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/post_model.dart';
import 'package:provider/provider.dart';
import '../../providers/posts_provider.dart';

class PollWidget extends StatelessWidget {
  final PostModel post;
  final String currentUserId;

  const PollWidget({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (post.poll == null) return const SizedBox.shrink();

    final poll = post.poll!;
    final totalVotes = poll.totalVotes;
    final hasVoted = poll.hasVoted(currentUserId);
    final isExpired = poll.isExpired;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(poll.options.length, (index) {
            final option = poll.options[index];
            final optionVotes = option.voterIds.length;
            final percentage = totalVotes > 0 ? (optionVotes / totalVotes) : 0.0;
            final isMyVote = option.voterIds.contains(currentUserId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GestureDetector(
                onTap: () {
                  if (isExpired) return;
                  // If it's single choice and we already voted for another option, it will switch
                  context.read<PostsProvider>().voteInPoll(post.id, index, currentUserId);
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isMyVote 
                      ? AppColors.primary.withValues(alpha: 0.1) 
                      : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMyVote ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (hasVoted || isExpired)
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isMyVote 
                                ? AppColors.primary.withValues(alpha: 0.2) 
                                : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  fontWeight: isMyVote ? FontWeight.bold : FontWeight.normal,
                                  color: isMyVote ? AppColors.primary : null,
                                ),
                              ),
                            ),
                            if (hasVoted || isExpired)
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isMyVote ? AppColors.primary : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalVotes أصوات',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (isExpired)
                Text(
                  'انتهى التصويت',
                  style: TextStyle(color: Colors.red[400], fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
