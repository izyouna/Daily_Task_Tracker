import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF121B22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Task Dashboard",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              authProvider.user?.email ?? '',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.cyanAccent),
            tooltip: "Add Category",
            onPressed: () => _showAddCategorySheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.label_outline, color: Colors.cyanAccent),
            tooltip: "Add Tag",
            onPressed: () => _showAddTagSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Container(
            color: const Color(0xFF1F2C34),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => _refreshTasks(),
                  decoration: InputDecoration(
                    hintText: "Search tasks...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              _refreshTasks();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF121B22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
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
                            label: const Text("All Categories"),
                            selected: isSelected,
                            selectedColor: Colors.cyan,
                            backgroundColor: const Color(0xFF121B22),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
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
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: catColor.withOpacity(0.8),
                          backgroundColor: const Color(0xFF121B22),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : catColor,
                            fontWeight: FontWeight.bold,
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
                          deleteIconColor: Colors.redAccent,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

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
                          label: Text("#${tag.name}", style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          selectedColor: Colors.tealAccent,
                          backgroundColor: const Color(0xFF121B22),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.tealAccent,
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
                          deleteIconColor: Colors.redAccent,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Status TabBar
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: "Pending"),
              Tab(text: "In Progress"),
              Tab(text: "Completed"),
            ],
          ),
          
          // Tasks List area
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : displayedTasks.isEmpty
                    ? Center(
                        child: Text(
                          "No tasks found.",
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: displayedTasks.length,
                        itemBuilder: (context, index) {
                          final task = displayedTasks[index];
                          final catColor = task.category != null
                              ? _parseColor(task.category!.colorHex)
                              : Colors.cyanAccent;
                              
                          return Card(
                            color: const Color(0xFF1F2C34),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: catColor.withOpacity(0.3), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Checkbox(
                                value: task.status == 'Completed',
                                activeColor: Colors.cyanAccent,
                                checkColor: Colors.black,
                                onChanged: (value) {
                                  if (value == null) return;
                                  final newStatus = value ? 'Completed' : 'Pending';
                                  taskProvider.updateTaskStatus(task.id, newStatus);
                                },
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  color: Colors.white,
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
                                    const SizedBox(height: 4),
                                    Text(
                                      task.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Category badge
                                      if (task.category != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: catColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            task.category!.name,
                                            style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      // Due Date
                                      if (task.dueDate != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 12, color: Colors.white38),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  if (task.tags.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      children: task.tags.map((tag) {
                                        return Text(
                                          "#${tag.name}",
                                          style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.white70),
                                color: const Color(0xFF1F2C34),
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
                                    const PopupMenuItem(
                                      value: 'progress',
                                      child: Text("Mark In Progress", style: TextStyle(color: Colors.white)),
                                    ),
                                  if (task.status != 'Pending')
                                    const PopupMenuItem(
                                      value: 'pending',
                                      child: Text("Mark Pending", style: TextStyle(color: Colors.white)),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text("Delete Task", style: TextStyle(color: Colors.redAccent)),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add, size: 28),
        onPressed: () => _showAddTaskSheet(context),
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
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  const Text(
                    "New Task",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title Input
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Task Title",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF121B22),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description Input
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Description (optional)",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF121B22),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Choose Category
                  const Text("Select Category", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: taskProvider.categories.map((cat) {
                      final isSel = categoryId == cat.id;
                      final col = _parseColor(cat.colorHex);
                      return ChoiceChip(
                        label: Text(cat.name),
                        selected: isSel,
                        selectedColor: col.withOpacity(0.8),
                        backgroundColor: const Color(0xFF121B22),
                        labelStyle: TextStyle(color: isSel ? Colors.white : col),
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
                  const Text("Attach Tags", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: taskProvider.tags.map((tag) {
                      final isSel = tagIds.contains(tag.id);
                      return FilterChip(
                        label: Text("#${tag.name}"),
                        selected: isSel,
                        selectedColor: Colors.tealAccent,
                        backgroundColor: const Color(0xFF121B22),
                        labelStyle: TextStyle(color: isSel ? Colors.black : Colors.tealAccent),
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
                            ? "No Due Date"
                            : "Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, color: Colors.cyanAccent),
                        label: const Text("Pick Date", style: TextStyle(color: Colors.cyanAccent)),
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
                        "Create Task",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
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
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  const Text(
                    "Add Category",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Category Name (e.g. Work, Gym)",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF121B22),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Color selection options
                  const Text("Select Color", style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                            shape: BoxShape.circle,
                            border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        final ok = await Provider.of<TaskProvider>(context, listen: false)
                            .createCategory(nameController.text.trim(), hexColor);
                        if (ok && mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text("Save Category", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              const Text(
                "Add Tag",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Tag name (e.g. Urgent, Later)",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF121B22),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final ok = await Provider.of<TaskProvider>(context, listen: false)
                        .createTag(nameController.text.trim());
                    if (ok && mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("Save Tag", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
