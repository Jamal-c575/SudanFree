import re

path = 'lib/views/posts/posts_feed_screen.dart'
with open(path, 'r') as f:
    content = f.read()

# Replace the wrong Stack definition
wrong_start = """    return Scaffold(
      body: Stack(
        body: NotificationListener<ScrollNotification>("""

correct_start = """    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    elevation: 0,
                    centerTitle: false,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    title: Text(
                      AppLocalizations.of(context)!.community,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.search,
                            color: Theme.of(context).iconTheme.color),
                        onPressed: () {
                          setState(() {
                            _showSearch = !_showSearch;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    bottom: _showSearch
                        ? PreferredSize(
                            preferredSize: const Size.fromHeight(100),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  SmartSearchField(
                                    controller: _searchController,
                                    hintText: AppLocalizations.of(context)!.searchPosts,
                                    searchContext: SearchContext.community,
                                    accentColor: AppColors.primary,
                                    onSearch: (val) =>
                                        setState(() => _searchQuery = val),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 36,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _buildCategoryChip(
                                          AppLocalizations.of(context)!.all,
                                          _selectedGroup == null,
                                          () {
                                            setState(() => _selectedGroup = null);
                                            _fetchAds();
                                            context
                                                .read<PostsProvider>()
                                                .fetchPosts(categoryGroup: null);
                                          },
                                          onLongPress: () {
                                            if (_pinnedGroup == null) return;
                                            _pinCategory(null, isUnpin: true);
                                            setState(() => _selectedGroup = null);
                                            context
                                                .read<PostsProvider>()
                                                .fetchPosts(categoryGroup: null);
                                          },
                                          isPinned: _pinnedGroup == null,
                                        ),
                                        ...PostCategoryGroup.values.map((group) {
                                          return _buildCategoryChip(
                                            group.getName(locale),
                                            _selectedGroup == group,
                                            () {
                                              setState(() => _selectedGroup = group);
                                              _fetchAds();
                                              context
                                                  .read<PostsProvider>()
                                                  .fetchPosts(categoryGroup: group);
                                            },
                                            onLongPress: () {
                                              if (_pinnedGroup == group) {
                                                _pinCategory(null, isUnpin: true);
                                                setState(() => _selectedGroup = null);
                                                context
                                                    .read<PostsProvider>()
                                                    .fetchPosts(categoryGroup: null);
                                              } else {
                                                _pinCategory(group);
                                                setState(
                                                    () => _selectedGroup = group);
                                                context
                                                    .read<PostsProvider>()
                                                    .fetchPosts(categoryGroup: group);
                                              }
                                            },
                                            isPinned: _pinnedGroup == group,
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (postsProvider.trendingPosts.isNotEmpty &&
                      _selectedGroup == null &&
                      _searchQuery.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildTrendingSection(
                          context, postsProvider.trendingPosts, locale),
                    ),
                ],
                body: NotificationListener<ScrollNotification>("""

# 1. We replace the incorrect part 
content = content.replace(wrong_start, correct_start)

# 2. We remove the old Positioned.fill section which starts at line 464 down to 597
# Since we pasted the fixed version above, we can just delete from `        children: [` to `            ),` before `if (canPost) {`
# We'll use regex for this chunk removal
import re
pattern = re.compile(r'children: \[\n\s*// 1\. المحتوى الرئيسي\n\s*Positioned\.fill\(.*?// 2\. زر النشر الذكي والمتحرك', re.DOTALL)
content = re.sub(pattern, '// 2. زر النشر الذكي والمتحرك', content)

# 3. The SmartDraggableFab was inside `if (canPost) { SmartDraggableFab(...) }`
# Which makes it a Set instead of a single element in a list. It should be `if (canPost) SmartDraggableFab(...)`
content = content.replace("if (canPost) {", "if (canPost)")
content = content.replace("            )\n          },", "            ),")

# 4. Expected to find ';' after the Stack block ? Line 616
content = content.replace("      ),\n    )\n  }", "      ),\n    );\n  }")

with open(path, 'w') as f:
    f.write(content)
print("Fixed posts_feed_screen.dart")
