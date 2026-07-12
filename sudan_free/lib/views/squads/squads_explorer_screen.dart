import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/squad_model.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../profile/squad_profile_screen.dart';
import 'create_squad_screen.dart';
import '../../widgets/buttons/smart_draggable_fab.dart';
import '../../core/constants/sudan_locations.dart';
import '../../widgets/common/morph_transition.dart';
import '../../widgets/common/glass_container.dart';
import 'package:sudan_free/l10n/generated/app_localizations.dart';
import '../home/home_screen.dart'; // To access BottomBarVisibilityProvider

class SquadsExplorerScreen extends StatefulWidget {
  const SquadsExplorerScreen({super.key});

  @override
  State<SquadsExplorerScreen> createState() => _SquadsExplorerScreenState();
}

class _SquadsExplorerScreenState extends State<SquadsExplorerScreen> {
  SquadCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.exploreSquads),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Consumer<BottomBarVisibilityProvider?>(
                    builder: (context, visibilityProvider, child) {
                      final isVisible = visibilityProvider?.isVisible ?? true;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: isVisible ? 70 : 0,
                        curve: Curves.easeOutCubic,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: GlassContainer(
                              borderRadius: BorderRadius.circular(12),
                              blur: 15,
                              opacity: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.3
                                  : 0.6,
                              color: Theme.of(context).cardColor,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.searchSquads,
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16), // Added spacing here
                      // Category Filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: SquadCategory.values.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategory == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = null),
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            borderRadius: BorderRadius.circular(16),
                            blur: 15,
                            opacity: isSelected
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.3
                                    : 0.4)
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.1
                                    : 0.2),
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).cardColor,
                            border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: isSelected ? 0.5 : 0.1)),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSelected ? 14 : 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.6) ??
                                        Colors.grey,
                                fontFamily: 'Cairo',
                              ),
                              child: Center(child: Text(AppLocalizations.of(context)!.all)),
                            ),
                          ),
                        ),
                      );
                    }
                    final cat = SquadCategory.values[index - 1];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(
                            () => _selectedCategory = isSelected ? null : cat),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          borderRadius: BorderRadius.circular(16),
                          blur: 15,
                          opacity: isSelected
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? 0.3
                                  : 0.4)
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? 0.1
                                  : 0.2),
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).cardColor,
                          border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: isSelected ? 0.5 : 0.1)),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: isSelected ? 14 : 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.6) ??
                                      Colors.grey,
                              fontFamily: 'Cairo',
                            ),
                            child: Center(child: Text(cat.getName(locale))),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
              ];
            },
            body: StreamBuilder<QuerySnapshot>(
                  stream: _selectedCategory == null
                      ? FirebaseFirestore.instance
                          .collection('squads')
                          .orderBy('rating', descending: true)
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('squads')
                          .where('category', isEqualTo: _selectedCategory!.name)
                          .orderBy('rating', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    final filteredDocs = docs.where((doc) {
                      if (_searchQuery.isEmpty) return true;
                      final squadName =
                          (doc.data() as Map<String, dynamic>)['name']
                                  ?.toString() ??
                              '';
                      return squadName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child:
                            Text(AppLocalizations.of(context)!.noSquadsFound),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final squad =
                            SquadModel.fromFirestore(filteredDocs[index]);
                        return MorphTransition(
                          openScreen: SquadProfileScreen(squad: squad),
                          closedBuilder: (context, openContainer) => GlassContainer(
                          margin: const EdgeInsets.only(bottom: 16),
                          blur: 15,
                          opacity:
                              Theme.of(context).brightness == Brightness.dark
                                  ? 0.3
                                  : 0.6,
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).cardColor,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: squad.squadImageUrl != null
                                  ? NetworkImage(squad.squadImageUrl!)
                                  : null,
                              child: squad.squadImageUrl == null
                                  ? const Icon(Icons.groups,
                                      color: AppColors.primary)
                                  : null,
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: Text(squad.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: squad.isAvailable
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle,
                                          size: 8,
                                          color: squad.isAvailable
                                              ? Colors.green
                                              : Colors.red),
                                      const SizedBox(width: 4),
                                      Text(
                                        squad.isAvailable
                                            ? (AppLocalizations.of(context)!.available)
                                            : (AppLocalizations.of(context)!.busy),
                                        style: TextStyle(
                                            color: squad.isAvailable
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(squad.category.getName(locale),
                                        style: const TextStyle(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.bold)),
                                    if (squad.state != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          '${SudanLocations.getStateName(squad.state!, locale)}${squad.locality != null ? " - ${SudanLocations.getLocalityName(squad.locality!, locale)}" : ""}',
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(squad.rating.toStringAsFixed(1)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.work,
                                        color: Colors.grey, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                        '${squad.completedJobs} ${AppLocalizations.of(context)!.jobs1}'),
                                  ],
                                ),
                              ],
                            ),
                            onTap: openContainer,
                          ),
                        ),
                      );
                      },
                    );
                  },
          ),
          ),
          if (user != null &&
              user.role != UserRole.client &&
              user.role != UserRole.shop)
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('squads')
                  .where('memberIds', arrayContains: user.id)
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                final isInSquad = snapshot.data?.docs.isNotEmpty ?? false;
                if (isInSquad) return const SizedBox.shrink();

                return SmartDraggableFab(
                  heroTag: 'create_squad_fab',
                  icon: Icons.add,
                  label: AppLocalizations.of(context)!.createSquad,
                  locale: locale,
                  initialBottom: MediaQuery.of(context).padding.bottom +
                      82.0, // navBar + safe area
                  openBuilder: (context, openContainer) => const CreateSquadScreen(),
                );
              },
            ),
        ],
      ),
    );
  }
}
