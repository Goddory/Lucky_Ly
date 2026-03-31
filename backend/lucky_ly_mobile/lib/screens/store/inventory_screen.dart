import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../providers/store_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final inventory = store.inventory;

    // Tính toán tổng giá trị kho tạm thời một cách an toàn
    double totalValue = 0;
    for (var item in inventory) {
      final priceRaw = item['price'];
      if (priceRaw is num) {
        totalValue += priceRaw.toDouble();
      } else if (priceRaw is String) {
        totalValue += double.tryParse(priceRaw) ?? 0;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main Scrollable Content
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInventorySummaryCard(totalValue, inventory.length),
                      const SizedBox(height: 24),
                      if (store.isLoading && inventory.isEmpty)
                        const Center(child: CircularProgressIndicator(color: Color(0xFF8F2BAD)))
                      else if (inventory.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text('Kho đang trống', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        _buildInventoryList(inventory, context),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Action Button (FAB)
          Positioned(
            bottom: 100,
            right: 24,
            child: _buildFloatingActionButton(context),
          ),

          // Floating Bottom Navigation Bar
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFFBF5F8),
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF8F2BAD)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Kho vật phẩm',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.bold,
          color: Color(0xFF8F2BAD),
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildInventorySummaryCard(double totalValue, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8F2BAD), Color(0xFFE37CFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F2BAD).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng giá trị kho',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalValue.toStringAsFixed(0)}đ',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Plus Jakarta Sans'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildGlassPill('$count Vật phẩm'),
              const SizedBox(width: 8),
              _buildGlassPill('Cập nhật ngay'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInventoryList(List<dynamic> inventory, BuildContext context) {
    return Column(
      children: inventory.map((item) {
        final category = item['category'] ?? 'Vật phẩm';
        final is3D = category.toString().contains('3D') || category.toString().contains('Model');
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InventoryItemCard(
            item: item,
            category: category,
            title: item['item_name'] ?? 'Không tên',
            price: '${item['price']}đ',
            icon: is3D ? Icons.view_in_ar : Icons.stars_rounded,
            iconColor: is3D ? const Color(0xFF8F2BAD) : const Color(0xFFB70049),
            iconBgColor: is3D ? const Color(0xFFE37CFF).withOpacity(0.3) : const Color(0xFFFFC2CA),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF8F2BAD), Color(0xFFE37CFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F2BAD).withOpacity(0.3),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => _showItemDialog(context),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  void _showItemDialog(BuildContext context, [Map<String, dynamic>? item]) {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(item: item),
    );
  }

  Widget _buildFloatingBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(color: const Color(0xFF302E30).withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard, 'Dashboard', false),
              _buildNavItem(Icons.inventory_2, 'Inventory', true),
              _buildNavItem(Icons.shopping_bag, 'Orders', false),
              _buildNavItem(Icons.insights, 'Insights', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE37CFF).withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF8F2BAD) : const Color(0xFFB0ACAF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF8F2BAD) : const Color(0xFFB0ACAF),
          ),
        ),
      ],
    );
  }
}

class InventoryItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String category;
  final String title;
  final String price;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.category,
    required this.title,
    required this.price,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF302E30).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF302E30),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8F2BAD),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildActionButton(context, Icons.edit, const Color(0xFF5E5B5D), const Color(0xFFECE6EA), isEdit: true),
              const SizedBox(height: 8),
              _buildActionButton(context, Icons.delete, const Color(0xFFB41340), const Color(0xFFECE6EA), isEdit: false),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, Color iconColor, Color bgColor, {required bool isEdit}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 18),
        onPressed: () {
          if (isEdit) {
            showDialog(
              context: context,
              builder: (ctx) => _ItemFormDialog(item: item),
            );
          } else {
            _confirmDelete(context);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              context.read<StoreProvider>().deleteItem(item['item_id']);
              Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ItemFormDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  const _ItemFormDialog({this.item});

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late String _category;
  String? _effectType;
  String? _selectedFilePath;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?['item_name'] ?? '');
    _descController = TextEditingController(text: widget.item?['description'] ?? '');
    _priceController = TextEditingController(text: (widget.item?['price'] ?? 0).toString());
    _category = widget.item?['category'] ?? 'Sticker';
    _effectType = widget.item?['effect_type'] ?? 'none';
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: kIsWeb,
        allowedExtensions: _category == 'Sticker' ? ['png', 'jpg', 'jpeg'] : ['glb', 'gltf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFilePath = file.path;
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Thêm vật phẩm' : 'Sửa vật phẩm'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                items: ['Sticker', 'Model (3D)']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _category = v!;
                    _selectedFilePath = null;
                    _selectedFileName = null;
                    _selectedFileBytes = null;
                  });
                },
                decoration: const InputDecoration(labelText: 'Loại vật phẩm'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: Icon(_selectedFileName != null ? Icons.check_circle : Icons.upload_file),
                label: Text(_selectedFileName != null ? 'Đổi file' : 'Chọn file'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: _selectedFileName != null ? Colors.green : null,
                ),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên vật phẩm'),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập giá' : null,
              ),
              DropdownButtonFormField<String>(
                value: _effectType,
                items: ['none', 'sparkle', 'glow', 'confetti']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _effectType = v!),
                decoration: const InputDecoration(labelText: 'Hiệu ứng'),
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (widget.item == null && _selectedFilePath == null && _selectedFileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn file!')),
        );
        return;
      }

      bool success;
      if (widget.item == null) {
        success = await context.read<StoreProvider>().addItem(
          name: _nameController.text,
          category: _category,
          price: double.parse(_priceController.text),
          description: _descController.text,
          effectType: _effectType,
          filePath: _selectedFilePath,
          fileBytes: _selectedFileBytes,
          fileName: _selectedFileName,
        );
      } else {
        success = await context.read<StoreProvider>().updateItem(widget.item!['item_id'], {
          'itemName': _nameController.text,
          'category': _category,
          'price': double.parse(_priceController.text),
          'description': _descController.text,
          'effectType': _effectType,
        });
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thành công!')),
        );
      }
    }
  }
}
