/// 收支分类体系 - 2级分类

class Category {
  final String name;
  final String icon;
  const Category({required this.name, required this.icon});
}

class MajorCategory {
  final String name;
  final String icon;
  final List<Category> subCategories;
  const MajorCategory({
    required this.name,
    required this.icon,
    required this.subCategories,
  });
}

/// 支出分类（12大类，约70小类）
const List<MajorCategory> expenseCategories = [
  MajorCategory(name: '餐饮饮食', icon: 'restaurant', subCategories: [
    Category(name: '早餐', icon: 'free_breakfast'),
    Category(name: '午餐', icon: 'lunch_dining'),
    Category(name: '晚餐', icon: 'dinner_dining'),
    Category(name: '零食', icon: 'bakery_dining'),
    Category(name: '饮品', icon: 'local_cafe'),
    Category(name: '水果', icon: 'eco'),
    Category(name: '外卖', icon: 'delivery_dining'),
    Category(name: '聚餐', icon: 'groups'),
  ]),
  MajorCategory(name: '交通出行', icon: 'directions_car', subCategories: [
    Category(name: '公交', icon: 'directions_bus'),
    Category(name: '地铁', icon: 'subway'),
    Category(name: '打车/网约车', icon: 'local_taxi'),
    Category(name: '加油', icon: 'local_gas_station'),
    Category(name: '停车', icon: 'local_parking'),
    Category(name: '火车/高铁', icon: 'train'),
    Category(name: '飞机', icon: 'flight'),
    Category(name: '共享单车', icon: 'pedal_bike'),
  ]),
  MajorCategory(name: '购物消费', icon: 'shopping_bag', subCategories: [
    Category(name: '日用品', icon: 'cleaning_services'),
    Category(name: '衣物鞋帽', icon: 'checkroom'),
    Category(name: '数码电子', icon: 'devices'),
    Category(name: '家居用品', icon: 'chair'),
    Category(name: '化妆品/护肤', icon: 'face'),
    Category(name: '书籍', icon: 'menu_book'),
    Category(name: '礼品', icon: 'card_giftcard'),
  ]),
  MajorCategory(name: '居住住房', icon: 'home', subCategories: [
    Category(name: '房租', icon: 'apartment'),
    Category(name: '水费', icon: 'water_drop'),
    Category(name: '电费', icon: 'electric_bolt'),
    Category(name: '燃气费', icon: 'local_fire_department'),
    Category(name: '物业费', icon: 'business'),
    Category(name: '网费', icon: 'wifi'),
    Category(name: '维修', icon: 'build'),
  ]),
  MajorCategory(name: '通讯网络', icon: 'smartphone', subCategories: [
    Category(name: '手机话费', icon: 'phone_android'),
    Category(name: '宽带费', icon: 'router'),
  ]),
  MajorCategory(name: '医疗健康', icon: 'local_hospital', subCategories: [
    Category(name: '看病/挂号', icon: 'medical_services'),
    Category(name: '药品', icon: 'medication'),
    Category(name: '体检', icon: 'biotech'),
    Category(name: '牙科', icon: 'mood'),
    Category(name: '保健品', icon: 'health_and_safety'),
  ]),
  MajorCategory(name: '教育学习', icon: 'school', subCategories: [
    Category(name: '培训课程', icon: 'cast_for_education'),
    Category(name: '书本文具', icon: 'edit_note'),
    Category(name: '考试报名', icon: 'assignment'),
    Category(name: '网课会员', icon: 'computer'),
  ]),
  MajorCategory(name: '娱乐休闲', icon: 'sports_esports', subCategories: [
    Category(name: '电影', icon: 'movie'),
    Category(name: '演出', icon: 'theater_comedy'),
    Category(name: '游戏', icon: 'videogame_asset'),
    Category(name: '旅游', icon: 'flight_takeoff'),
    Category(name: '运动健身', icon: 'fitness_center'),
    Category(name: 'KTV', icon: 'mic'),
    Category(name: '景点门票', icon: 'attractions'),
  ]),
  MajorCategory(name: '人情社交', icon: 'people', subCategories: [
    Category(name: '红包/礼金', icon: 'redeem'),
    Category(name: '请客吃饭', icon: 'dinner_dining'),
    Category(name: '礼物', icon: 'featured_seasonal_and_gifts'),
    Category(name: '捐款', icon: 'volunteer_activism'),
  ]),
  MajorCategory(name: '金融保险', icon: 'account_balance', subCategories: [
    Category(name: '银行手续费', icon: 'account_balance_wallet'),
    Category(name: '保险', icon: 'verified_user'),
    Category(name: '贷款还款', icon: 'payments'),
    Category(name: '理财亏损', icon: 'trending_down'),
  ]),
  MajorCategory(name: '宠物育儿', icon: 'pets', subCategories: [
    Category(name: '宠物食品', icon: 'pet_supplies'),
    Category(name: '宠物医疗', icon: 'local_hospital'),
    Category(name: '宠物用品', icon: 'shopping_basket'),
    Category(name: '奶粉/尿布', icon: 'baby_changing_station'),
    Category(name: '玩具', icon: 'toys'),
    Category(name: '托管/保姆', icon: 'child_care'),
  ]),
  MajorCategory(name: '其他杂项', icon: 'more_horiz', subCategories: [
    Category(name: '快递费', icon: 'local_shipping'),
    Category(name: '办公用品', icon: 'work'),
    Category(name: '其他', icon: 'help_outline'),
  ]),
];

/// 收入分类（4大类，约14小类）
const List<MajorCategory> incomeCategories = [
  MajorCategory(name: '职业收入', icon: 'work', subCategories: [
    Category(name: '工资', icon: 'payments'),
    Category(name: '奖金', icon: 'emoji_events'),
    Category(name: '兼职', icon: 'handyman'),
    Category(name: '加班补贴', icon: 'more_time'),
  ]),
  MajorCategory(name: '投资理财', icon: 'trending_up', subCategories: [
    Category(name: '股票基金收益', icon: 'show_chart'),
    Category(name: '利息收入', icon: 'account_balance'),
    Category(name: '房租收入', icon: 'apartment'),
    Category(name: '分红', icon: 'diamond'),
  ]),
  MajorCategory(name: '人情往来', icon: 'redeem', subCategories: [
    Category(name: '红包收入', icon: 'featured_seasonal_and_gifts'),
    Category(name: '礼金收入', icon: 'card_giftcard'),
    Category(name: '报销退款', icon: 'currency_exchange'),
  ]),
  MajorCategory(name: '其他收入', icon: 'more_horiz', subCategories: [
    Category(name: '其他收入', icon: 'help_outline'),
  ]),
];

/// 默认使用支出分类（向后兼容）
const List<MajorCategory> defaultCategories = expenseCategories;

/// 根据类型获取分类列表
List<MajorCategory> getCategoriesForType(String type) {
  return type == 'income' ? incomeCategories : expenseCategories;
}

/// 所有大级分类名称
List<String> get majorCategoryNames =>
    expenseCategories.map((c) => c.name).toList();

/// 根据大类名获取小类
List<Category> getSubCategories(String majorName) {
  for (final list in [expenseCategories, incomeCategories]) {
    final major = list.firstWhere(
      (c) => c.name == majorName,
      orElse: () => list.first,
    );
    final found = list.any((c) => c.name == majorName);
    if (found) return major.subCategories;
  }
  return expenseCategories.first.subCategories;
}

String getMajorIcon(String majorName) {
  for (final list in [expenseCategories, incomeCategories]) {
    final major = list.firstWhere(
      (c) => c.name == majorName,
      orElse: () => list.first,
    );
    final found = list.any((c) => c.name == majorName);
    if (found) return major.icon;
  }
  return expenseCategories.first.icon;
}

/// 支付方式
const List<String> paymentMethods = ['微信', '支付宝', '银行卡', '现金', '其他'];

/// 支付方式对应图标
const Map<String, String> paymentIcons = {
  '微信': 'chat',
  '支付宝': 'account_balance_wallet',
  '银行卡': 'credit_card',
  '现金': 'money',
  '其他': 'more_horiz',
};
