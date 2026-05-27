import '../models/category_model.dart';

class CategoryService {
  Future<List<CategoryModel>> getCategories() async {
    return const [
      CategoryModel(id: 1, name: 'Semua', icon: '🛒'),
      CategoryModel(id: 2, name: 'Beras', icon: '🍚'),
      CategoryModel(id: 3, name: 'Minyak', icon: '🫗'),
      CategoryModel(id: 4, name: 'Susu', icon: '🥛'),
      CategoryModel(id: 5, name: 'Deterjen', icon: '🧼'),
      CategoryModel(id: 6, name: 'Snack', icon: '🍪'),
    ];
  }
}

