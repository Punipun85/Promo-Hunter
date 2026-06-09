import '../models/category_model.dart';
import 'supabase_service.dart';

class CategoryService {
  CategoryService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;

  Future<List<CategoryModel>> getCategories() async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client.from('categories').select().order('name');
        return [
          const CategoryModel(id: 1, name: 'Semua', icon: 'all'),
          ...(response as List)
              .map((item) => CategoryModel.fromMap(item as Map<String, dynamic>)),
        ];
      } catch (_) {
        // Fallback to local categories.
      }
    }

    return const [
      CategoryModel(id: 1, name: 'Semua', icon: 'all'),
      CategoryModel(id: 2, name: 'Beras', icon: 'rice'),
      CategoryModel(id: 3, name: 'Minyak', icon: 'oil'),
      CategoryModel(id: 4, name: 'Susu', icon: 'milk'),
      CategoryModel(id: 5, name: 'Deterjen', icon: 'soap'),
      CategoryModel(id: 6, name: 'Snack', icon: 'snack'),
      CategoryModel(id: 7, name: 'Bumbu', icon: 'sauce'),
      CategoryModel(id: 8, name: 'Frozen Food', icon: 'frozen'),
    ];
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('categories').insert({
          'name': category.name,
          'icon': category.icon,
        });
      } catch (_) {}
    }
    return category;
  }

  Future<CategoryModel> updateCategory(CategoryModel category) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('categories').update({
          'name': category.name,
          'icon': category.icon,
        }).eq('id', category.id);
      } catch (_) {}
    }
    return category;
  }

  Future<void> deleteCategory(int categoryId) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.from('categories').delete().eq('id', categoryId);
      } catch (_) {}
    }
  }
}
