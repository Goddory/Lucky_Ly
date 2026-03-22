/// Gift catalog — static data for all themed gifts.
/// Each theme has 5 models (3D .glb) and 5 stickers (PNG images).

class GiftModel {
  final String id;
  final String name;
  final String assetPath; // path to .glb file in assets/
  final String thumbnailIcon; // material icon name for placeholder
  final String theme;

  const GiftModel({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.thumbnailIcon,
    required this.theme,
  });
}

class GiftSticker {
  final String id;
  final String name;
  final String assetPath; // path to PNG file in assets/
  final String theme;

  const GiftSticker({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.theme,
  });
}

class GiftCatalog {
  // ─── Tết Models ───
  static const tetModels = [
    GiftModel(id: 'tet_lixi_red', name: 'Bao Lì Xì Đỏ', assetPath: 'assets/models/tet/lixi_red.glb', thumbnailIcon: 'redeem', theme: 'tet'),
    GiftModel(id: 'tet_lixi_gold', name: 'Bao Lì Xì Vàng', assetPath: 'assets/models/tet/lixi_gold.glb', thumbnailIcon: 'card_giftcard', theme: 'tet'),
    GiftModel(id: 'tet_lixi_hoamai', name: 'Bao Lì Xì Hoa Mai', assetPath: 'assets/models/tet/lixi_hoamai.glb', thumbnailIcon: 'local_florist', theme: 'tet'),
    GiftModel(id: 'tet_lixi_dragon', name: 'Bao Lì Xì Rồng', assetPath: 'assets/models/tet/lixi_dragon.glb', thumbnailIcon: 'pets', theme: 'tet'),
    GiftModel(id: 'tet_lixi_phucloc', name: 'Bao Lì Xì Phúc Lộc', assetPath: 'assets/models/tet/lixi_phucloc.glb', thumbnailIcon: 'emoji_events', theme: 'tet'),
  ];

  // ─── Valentine Models ───
  static const valentineModels = [
    GiftModel(id: 'val_heart_box', name: 'Hộp Quà Trái Tim', assetPath: 'assets/models/valentine/heart_box.glb', thumbnailIcon: 'favorite', theme: 'valentine'),
    GiftModel(id: 'val_ribbon_box', name: 'Hộp Quà Nơ', assetPath: 'assets/models/valentine/ribbon_box.glb', thumbnailIcon: 'card_giftcard', theme: 'valentine'),
    GiftModel(id: 'val_teddy', name: 'Gấu Bông', assetPath: 'assets/models/valentine/teddy.glb', thumbnailIcon: 'smart_toy', theme: 'valentine'),
    GiftModel(id: 'val_bouquet', name: 'Bó Hoa', assetPath: 'assets/models/valentine/bouquet.glb', thumbnailIcon: 'local_florist', theme: 'valentine'),
    GiftModel(id: 'val_chocolate', name: 'Socola', assetPath: 'assets/models/valentine/chocolate.glb', thumbnailIcon: 'cake', theme: 'valentine'),
  ];

  // ─── Tết Stickers ───
  static const tetStickers = [
    GiftSticker(id: 'tet_hoamai', name: 'Hoa Mai', assetPath: 'assets/stickers/tet/hoa_mai.png', theme: 'tet'),
    GiftSticker(id: 'tet_hoadao', name: 'Hoa Đào', assetPath: 'assets/stickers/tet/hoa_dao.png', theme: 'tet'),
    GiftSticker(id: 'tet_phaoHoa', name: 'Pháo Hoa', assetPath: 'assets/stickers/tet/phao_hoa.png', theme: 'tet'),
    GiftSticker(id: 'tet_caudoi', name: 'Câu Đối', assetPath: 'assets/stickers/tet/cau_doi.png', theme: 'tet'),
    GiftSticker(id: 'tet_denlong', name: 'Đèn Lồng', assetPath: 'assets/stickers/tet/den_long.png', theme: 'tet'),
  ];

  // ─── Valentine Stickers ───
  static const valentineStickers = [
    GiftSticker(id: 'val_heart', name: 'Trái Tim', assetPath: 'assets/stickers/valentine/heart.png', theme: 'valentine'),
    GiftSticker(id: 'val_rose', name: 'Hoa Hồng', assetPath: 'assets/stickers/valentine/rose.png', theme: 'valentine'),
    GiftSticker(id: 'val_cupid', name: 'Cánh Cupid', assetPath: 'assets/stickers/valentine/cupid.png', theme: 'valentine'),
    GiftSticker(id: 'val_choco', name: 'Chocolate', assetPath: 'assets/stickers/valentine/chocolate.png', theme: 'valentine'),
    GiftSticker(id: 'val_letter', name: 'Love Letter', assetPath: 'assets/stickers/valentine/love_letter.png', theme: 'valentine'),
  ];

  static List<GiftModel> getModels(String theme) {
    return theme == 'tet' ? tetModels : valentineModels;
  }

  static List<GiftSticker> getStickers(String theme) {
    return theme == 'tet' ? tetStickers : valentineStickers;
  }
}
