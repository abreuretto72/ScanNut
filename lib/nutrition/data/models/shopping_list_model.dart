
class ShoppingItem {
  final String id;
  final String name;
  final String normalizedName;
  final ShoppingQuantity quantity;
  final String quantityDisplay;
  final int kcalTotal;
  final int occurrences;
  final ShoppingCheckbox checkbox;
  final String category;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.quantity,
    required this.quantityDisplay,
    required this.kcalTotal,
    required this.occurrences,
    this.checkbox = const ShoppingCheckbox(),
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'normalizedName': normalizedName,
    'quantity': quantity.toJson(),
    'quantityDisplay': quantityDisplay,
    'kcalTotal': kcalTotal,
    'occurrences': occurrences,
    'checkbox': checkbox.toJson(),
    'category': category,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'],
    name: json['name'],
    normalizedName: json['normalizedName'],
    quantity: ShoppingQuantity.fromJson(json['quantity']),
    quantityDisplay: json['quantityDisplay'],
    kcalTotal: json['kcalTotal'],
    occurrences: json['occurrences'],
    checkbox: ShoppingCheckbox.fromJson(json['checkbox']),
    category: json['category'],
  );
}

class ShoppingQuantity {
  final double value;
  final String unit; // unid, g, kg, ml, L

  ShoppingQuantity({required this.value, required this.unit});

  Map<String, dynamic> toJson() => {'value': value, 'unit': unit};

  factory ShoppingQuantity.fromJson(Map<String, dynamic> json) => ShoppingQuantity(
    value: (json['value'] as num).toDouble(),
    unit: json['unit'],
  );
}

class ShoppingCheckbox {
  final bool defaultChecked;

  const ShoppingCheckbox({this.defaultChecked = false});

  Map<String, dynamic> toJson() => {'defaultChecked': defaultChecked};

  factory ShoppingCheckbox.fromJson(Map<String, dynamic> json) => ShoppingCheckbox(
    defaultChecked: json['defaultChecked'] ?? false,
  );
}

class ShoppingListCategory {
  final String id;
  final String title;
  final int order;
  final List<ShoppingItem> items;

  ShoppingListCategory({
    required this.id,
    required this.title,
    required this.order,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'order': order,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory ShoppingListCategory.fromJson(Map<String, dynamic> json) => ShoppingListCategory(
    id: json['id'],
    title: json['title'],
    order: json['order'],
    items: (json['items'] as List).map((e) => ShoppingItem.fromJson(e)).toList(),
  );
}

class WeeklyShoppingList {
  final int schemaVersion;
  final String menuId;
  final String periodType; // weekly | 28days
  final int weekIndex;
  final String weekLabel;
  final DateTime startDate;
  final DateTime endDate;
  final String objective;
  final DateTime generatedAt;
  final List<ShoppingListCategory> categories;

  WeeklyShoppingList({
    this.schemaVersion = 1,
    required this.menuId,
    required this.periodType,
    required this.weekIndex,
    required this.weekLabel,
    required this.startDate,
    required this.endDate,
    required this.objective,
    required this.generatedAt,
    required this.categories,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'menuId': menuId,
    'periodType': periodType,
    'weekIndex': weekIndex,
    'weekLabel': weekLabel,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'objective': objective,
    'generatedAt': generatedAt.toIso8601String(),
    'categories': categories.map((e) => e.toJson()).toList(),
  };

  factory WeeklyShoppingList.fromJson(Map<String, dynamic> json) => WeeklyShoppingList(
    schemaVersion: json['schemaVersion'] ?? 1,
    menuId: json['menuId'],
    periodType: json['periodType'],
    weekIndex: json['weekIndex'],
    weekLabel: json['weekLabel'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    objective: json['objective'],
    generatedAt: DateTime.parse(json['generatedAt']),
    categories: (json['categories'] as List).map((e) => ShoppingListCategory.fromJson(e)).toList(),
  );
}
