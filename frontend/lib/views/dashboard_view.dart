import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/tag.dart';
import 'login_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedCategoryId;
  final Set<String> _selectedTagIds = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.fetchTasks();
      taskProvider.fetchCategories();
      taskProvider.fetchTags();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _refreshTasks();
  }

  String get _currentStatus {
    switch (_tabController.index) {
      case 0:
        return 'Pending';
      case 1:
        return 'In Progress';
      case 2:
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  void _refreshTasks() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.fetchTasks(
      status: _currentStatus,
      categoryId: _selectedCategoryId,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF7F8C8D);
    }
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  Widget _buildXPBar(double progress) {
    final int totalSegments = 10;
    final int filledSegments = (progress * totalSegments).round();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "COMPLETION XP",
                style: GoogleFonts.pressStart2p(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Text(
                "${(progress * 100).toInt()}% XP",
                style: GoogleFonts.pressStart2p(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segmented Bar
          Row(
            children: List.generate(totalSegments, (index) {
              final isFilled = index < filledSegments;
              return Expanded(
                child: Container(
                  height: 16,
                  margin: EdgeInsets.only(right: index == totalSegments - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: isFilled ? const Color(0xFF4CAF50) : const Color(0xFFEFE9DB), // Green vs Light cream
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();

    // Filter tasks locally by tags if any tag is selected (Many-to-many filtering)
    List<Task> displayedTasks = taskProvider.tasks;
    if (_selectedTagIds.isNotEmpty) {
      displayedTasks = displayedTasks.where((task) {
        return task.tags.any((tag) => _selectedTagIds.contains(tag.id));
      }).toList();
    }

    // Calculate progress based on all tasks
    final totalTasksCount = taskProvider.tasks.length;
    final completedTasksCount = taskProvider.tasks.where((task) => task.status == 'Completed').length;
    final progress = totalTasksCount > 0 ? completedTasksCount / totalTasksCount : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.black, width: 3),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "QUEST LOG",
              style: GoogleFonts.pressStart2p(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              "Hero: ${authProvider.user?.email ?? ''}",
              style: GoogleFonts.vt323(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            tooltip: "Add Category",
            onPressed: () => _showAddCategorySheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.label_outline, color: Colors.black),
            tooltip: "Add Tag",
            onPressed: () => _showAddTagSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252)),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // XP Bar at top
          _buildXPBar(progress),

          // Search & Filter Panel
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEFE9DB),
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.vt323(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  onChanged: (_) => _refreshTasks(),
                  decoration: InputDecoration(
                    hintText: "SEARCH QUESTS...",
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black54),
                            onPressed: () {
                              _searchController.clear();
                              _refreshTasks();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Categories Horizontal List
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: taskProvider.categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedCategoryId == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: const Text("ALL CATEGORIES"),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFFEB3B), // Yellow
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: Colors.black, width: 2),
                            ),
                            labelStyle: GoogleFonts.vt323(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              _refreshTasks();
                            },
                          ),
                        );
                      }
                      
                      final cat = taskProvider.categories[index - 1];
                      final isSelected = _selectedCategoryId == cat.id;
                      final catColor = _parseColor(cat.colorHex);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InputChip(
                          label: Text(cat.name.toUpperCase()),
                          selected: isSelected,
                          selectedColor: catColor.withOpacity(0.3),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(color: isSelected ? catColor : Colors.black, width: 2),
                          ),
                          labelStyle: GoogleFonts.vt323(
                            color: isSelected ? catColor : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = isSelected ? null : cat.id;
                            });
                            _refreshTasks();
                          },
                          onDeleted: () {
                            taskProvider.deleteCategory(cat.id);
                          },
                          deleteIconColor: const Color(0xFFFF5252),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // Tags Horizontal List
                SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: taskProvider.tags.length,
                    itemBuilder: (context, index) {
                      final tag = taskProvider.tags[index];
                      final isSelected = _selectedTagIds.contains(tag.id);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text("#${tag.name.toUpperCase()}"),
                          selected: isSelected,
                          selectedColor: const Color(0xFF4CAF50).withOpacity(0.3),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(color: isSelected ? const Color(0xFF4CAF50) : Colors.black, width: 1.5),
                          ),
                          labelStyle: GoogleFonts.vt323(
                            color: isSelected ? const Color(0xFF4CAF50) : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTagIds.add(tag.id);
                              } else {
                                _selectedTagIds.remove(tag.id);
                              }
                            });
                          },
                          onDeleted: () {
                            taskProvider.deleteTag(tag.id);
                          },
                          deleteIconColor: const Color(0xFFFF5252),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Status TabBar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 2.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black,
              indicatorWeight: 4,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black45,
              labelStyle: GoogleFonts.pressStart2p(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.pressStart2p(fontSize: 10),
              tabs: const [
                Tab(text: "PENDING"),
                Tab(text: "DOING"),
                Tab(text: "DONE"),
              ],
            ),
          ),
          
          // Tasks List area
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : displayedTasks.isEmpty
                    ? Center(
                        child: Text(
                          "NO QUESTS FOUND.",
                          style: GoogleFonts.pressStart2p(color: Colors.black38, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: displayedTasks.length,
                        itemBuilder: (context, index) {
                          final task = displayedTasks[index];
                          final catColor = task.category != null
                              ? _parseColor(task.category!.colorHex)
                              : Colors.black;
                              
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Checkbox(
                                value: task.status == 'Completed',
                                activeColor: Colors.black,
                                checkColor: Colors.white,
                                onChanged: (value) {
                                  if (value == null) return;
                                  final newStatus = value ? 'Completed' : 'Pending';
                                  taskProvider.updateTaskStatus(task.id, newStatus);
                                },
                              ),
                              title: Text(
                                task.title.toUpperCase(),
                                style: GoogleFonts.pressStart2p(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  decoration: task.status == 'Completed'
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.description != null && task.description!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      task.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.vt323(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Category badge
                                      if (task.category != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: catColor.withOpacity(0.15),
                                            border: Border.all(color: catColor, width: 1.5),
                                          ),
                                          child: Text(
                                            task.category!.name.toUpperCase(),
                                            style: GoogleFonts.vt323(
                                              color: catColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      // Due Date
                                      if (task.dueDate != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 12, color: Colors.black54),
                                            const SizedBox(width: 4),
                                            Text(
                                              "DUE: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                                              style: GoogleFonts.vt323(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (task.tags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: task.tags.map((tag) {
                                        return Text(
                                          "#${tag.name.toUpperCase()}",
                                          style: GoogleFonts.vt323(
                                            color: Colors.black45,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.black),
                                color: Colors.white,
                                shape: Border.all(color: Colors.black, width: 2),
                                onSelected: (action) {
                                  if (action == 'delete') {
                                    taskProvider.deleteTask(task.id);
                                  } else if (action == 'progress') {
                                    taskProvider.updateTaskStatus(task.id, 'In Progress');
                                  } else if (action == 'pending') {
                                    taskProvider.updateTaskStatus(task.id, 'Pending');
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (task.status != 'In Progress')
                                    PopupMenuItem(
                                      value: 'progress',
                                      child: Text("DOING", style: GoogleFonts.vt323(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  if (task.status != 'Pending')
                                    PopupMenuItem(
                                      value: 'pending',
                                      child: Text("PENDING", style: GoogleFonts.vt323(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text("DELETE", style: GoogleFonts.vt323(color: const Color(0xFFFF5252), fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFFFEB3B), // Yellow
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.black, width: 2.5),
          ),
          child: const Icon(Icons.add, size: 28),
          onPressed: () => _showAddTaskSheet(context),
        ),
      ),
    );
  }

  // --- Add Task Sheet ---
  void _showAddTaskSheet(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? categoryId;
    DateTime? dueDate;
    final Set<String> tagIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF6EE),
      shape: const Border(
        top: BorderSide(color: Colors.black, width: 3.5),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "NEW QUEST (TASK)",
                    style: GoogleFonts.pressStart2p(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title Input
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.vt323(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: "QUEST TITLE",
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description Input
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    style: GoogleFonts.vt323(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: "QUEST DETAILS (OPTIONAL)",
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Choose Category
                  Text("SELECT CATEGORY", style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 10)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: taskProvider.categories.map((cat) {
                      final isSel = categoryId == cat.id;
                      final col = _parseColor(cat.colorHex);
                      return ChoiceChip(
                        label: Text(cat.name.toUpperCase()),
                        selected: isSel,
                        selectedColor: col.withOpacity(0.3),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: isSel ? col : Colors.black, width: 2),
                        ),
                        labelStyle: GoogleFonts.vt323(
                          color: isSel ? col : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            categoryId = selected ? cat.id : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Choose Tags
                  Text("ATTACH TAGS", style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 10)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: taskProvider.tags.map((tag) {
                      final isSel = tagIds.contains(tag.id);
                      return FilterChip(
                        label: Text("#${tag.name.toUpperCase()}"),
                        selected: isSel,
                        selectedColor: const Color(0xFF4CAF50).withOpacity(0.3),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: isSel ? const Color(0xFF4CAF50) : Colors.black, width: 1.5),
                        ),
                        labelStyle: GoogleFonts.vt323(
                          color: isSel ? const Color(0xFF4CAF50) : Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tagIds.add(tag.id);
                            } else {
                              tagIds.remove(tag.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Pick Due Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dueDate == null
                            ? "NO DUE DATE"
                            : "DUE: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",
                        style: GoogleFonts.vt323(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, color: Colors.black),
                        label: Text("PICK DATE", style: GoogleFonts.vt323(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (selectedDate != null) {
                            setModalState(() {
                              dueDate = selectedDate;
                            });
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        final ok = await taskProvider.createTask(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          categoryId: categoryId,
                          dueDate: dueDate,
                          tagIds: tagIds.toList(),
                        );
                        if (ok && mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text(
                        "ACCEPT QUEST",
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Add Category Sheet ---
  void _showAddCategorySheet(BuildContext context) {
    final nameController = TextEditingController();
    String hexColor = "#3498DB"; // Default color hex

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF6EE),
      shape: const Border(
        top: BorderSide(color: Colors.black, width: 3.5),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ADD CATEGORY",
                    style: GoogleFonts.pressStart2p(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.vt323(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: "CATEGORY NAME (e.g. WORK, GYM)",
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Color selection options
                  Text("SELECT COLOR", style: GoogleFonts.pressStart2p(color: Colors.black, fontSize: 10)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      "#3498DB", // Blue
                      "#2ECC71", // Green
                      "#E74C3C", // Red
                      "#F1C40F", // Yellow
                      "#9B59B6", // Purple
                      "#E67E22"  // Orange
                    ].map((col) {
                      final isSel = hexColor == col;
                      final colVal = _parseColor(col);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            hexColor = col;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colVal,
                            border: Border.all(
                              color: isSel ? Colors.black : Colors.black26,
                              width: isSel ? 3.0 : 1.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        final ok = await Provider.of<TaskProvider>(context, listen: false)
                            .createCategory(nameController.text.trim(), hexColor);
                        if (ok && mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text("SAVE CATEGORY"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Add Tag Sheet ---
  void _showAddTagSheet(BuildContext context) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFAF6EE),
      shape: const Border(
        top: BorderSide(color: Colors.black, width: 3.5),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ADD TAG",
                style: GoogleFonts.pressStart2p(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: GoogleFonts.vt323(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: "TAG NAME (e.g. URGENT, LATER)",
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final ok = await Provider.of<TaskProvider>(context, listen: false)
                        .createTag(nameController.text.trim());
                    if (ok && mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("SAVE TAG"),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
