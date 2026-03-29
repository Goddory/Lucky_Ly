import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/store_provider.dart';
import '../../app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final softPinkBg = const Color(0xFFFFF0F3);
  final accentPink = const Color(0xFFFF758F);

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

    return Scaffold(
      backgroundColor: softPinkBg,
      appBar: AppBar(
        title: Text('Kho vật phẩm', style: GoogleFonts.comfortaa(color: accentPink, fontWeight: FontWeight.w900)),
        backgroundColor: softPinkBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentPink),
      ),
      body: RefreshIndicator(
        onRefresh: () => store.fetchInventory(),
        child: store.isLoading && inventory.isEmpty
            ? Center(child: CircularProgressIndicator(color: accentPink))
            : inventory.isEmpty
                ? const _EmptyInventory()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: inventory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = inventory[index];
                      return _InventoryItemTile(item: item, accentPink: accentPink);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(context),
        backgroundColor: accentPink,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  void _showItemDialog(BuildContext context, [Map<String, dynamic>? item]) {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(item: item),
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accentPink;

  const _InventoryItemTile({required this.item, required this.accentPink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: accentPink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.stars_rounded, color: accentPink, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_name'] ?? 'Không tên',
                  style: GoogleFonts.comfortaa(color: const Color(0xFF2B2D42), fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['category']} • ${item['price']}đ',
                  style: GoogleFonts.beVietnamPro(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: accentPink, size: 22),
            onPressed: () {
               showDialog(
                context: context,
                builder: (ctx) => _ItemFormDialog(item: item),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4D6D), size: 22),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${item['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              context.read<StoreProvider>().deleteItem(item['id']);
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
      debugPrint('Opening file picker for category: $_category');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: kIsWeb,
        allowedExtensions: _category == 'Sticker' ? ['png', 'jpg', 'jpeg'] : ['glb', 'gltf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        debugPrint('File picked: ${file.name}, size: ${file.size}, path: ${file.path}, bytes: ${file.bytes?.length}');
        setState(() {
          _selectedFilePath = file.path;
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;
        });
      } else {
        debugPrint('File pick cancelled or failed');
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
                label: Text(_selectedFileName != null ? 'Đổi file' : 'Chọn file (${_category == 'Sticker' ? '.png' : '.glb'})'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: _selectedFileName != null ? Colors.green : null,
                ),
              ),
              if (_selectedFileName != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đã chọn: $_selectedFileName',
                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
    debugPrint('Submitting form: name=${_nameController.text}, path=$_selectedFilePath, bytesCount=${_selectedFileBytes?.length}');
    if (_formKey.currentState!.validate()) {
      if (widget.item == null && _selectedFilePath == null && _selectedFileBytes == null) {
        debugPrint('Validation failed: No file selected');
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
        // Cập nhật text (không đổi file ở đây để đơn giản)
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
          const SnackBar(content: Text('Thành công! Đã đồng bộ vào kho của bạn.')),
        );
      }
    }
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Kho đang trống', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
