import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/goal_models.dart';
import '../../core/model/nutrition_models.dart';
import '../../core/model/workout_models.dart';
import '../../core/nutrition/nutrition_csv_parser.dart';
import '../../core/nutrition/nutrition_xlsx_parser.dart';
import '../../core/nutrition/nutrition_xlsx_writer.dart';
import '../../core/nutrition/nutrition_score_calculator.dart';
import '../../data/local/database.dart';
import '../../data/providers/data_providers.dart';
import '../../data/providers/remote_providers.dart';

import '../../data/repositories/nutrition_repository.dart';
import 'nutrition_ui_state.dart';

// Helper to map Database's FoodCatalogData to domain FoodCatalogItem
FoodCatalogItem mapCatalogEntityToDomain(FoodCatalogData r) {
  return FoodCatalogItem(
    id: r.id,
    name: r.name,
    gramsPerServing: r.gramsPerServing,
    caloriesPerServing: r.caloriesPerServing,
    proteinPerServing: r.proteinPerServing,
    carbsPerServing: r.carbsPerServing,
    fatPerServing: r.fatPerServing,
    fiberPerServing: r.fiberPerServing,
    potassiumMg: r.potassiumMg,
    sodiumMg: r.sodiumMg,
    cholesterolMg: r.cholesterolMg,
    isFavorite: r.isFavorite,
    importBatchId: r.importBatchId,
  );
}

// Helper to map Domain FoodCatalogItem to Database's FoodCatalogData
FoodCatalogData mapDomainToCatalogData(FoodCatalogItem item) {
  return FoodCatalogData(
    id: item.id,
    name: item.name,
    gramsPerServing: item.gramsPerServing,
    caloriesPerServing: item.caloriesPerServing,
    proteinPerServing: item.proteinPerServing,
    carbsPerServing: item.carbsPerServing,
    fatPerServing: item.fatPerServing,
    fiberPerServing: item.fiberPerServing,
    potassiumMg: item.potassiumMg,
    sodiumMg: item.sodiumMg,
    cholesterolMg: item.cholesterolMg,
    isFavorite: item.isFavorite,
    importBatchId: item.importBatchId,
  );
}

const Object _undefined = Object();

class NutritionNotifier extends Notifier<NutritionUiState> {
  StreamSubscription? _goalSub;
  ActiveGoal? _cachedActiveGoal;
  StreamSubscription? _dataSub;
  StreamSubscription? _allSub;
  StreamSubscription? _templatesSub;
  StreamSubscription? _loggedSub;
  StreamSubscription? _favSub;
  StreamSubscription? _recentSub;
  StreamSubscription? _countSub;
  StreamSubscription? _catalogSub;
  Timer? _searchDebounce;

  String? _scannedBarcode;
  SweatPaymentProposal? _draftSweatPayment;
  bool _draftNutrientsRecorded = false;

  @override
  NutritionUiState build() {
    final today = currentLocalEpochDay();
    final db = ref.watch(gymDatabaseProvider);
    final nutritionRepo = ref.watch(nutritionRepositoryProvider);
    final workoutRepo = ref.watch(workoutRepositoryProvider);

    _goalSub = workoutRepo.observeActiveGoal().listen((goal) {
      _cachedActiveGoal = goal;
      _updateWith(activeGoal: goal);
    });

    _dataSub = nutritionRepo.nutritionData.listen((data) {
      _updateWith(nutritionData: data);
    });

    _allSub = nutritionRepo.observeAllNutrition().listen((allNut) {
      _updateWith(allNutrition: allNut);
    });

    _templatesSub = nutritionRepo.observeMealTemplates().listen((tmps) {
      _updateWith(mealTemplates: tmps);
    });

    _loggedSub = nutritionRepo.observeLoggedFoods(today).listen((logged) {
      _updateWith(loggedFoods: logged);
    });

    _favSub = nutritionRepo.observeFavorites().listen((favs) {
      _updateWith(favorites: favs);
    });

    _recentSub = nutritionRepo.observeRecentFoods(20).listen((recents) {
      _updateWith(recentFoods: recents);
    });

    _countSub = db.foodCatalogDao.observeCount().listen((count) {
      _updateWith(foodCatalogCount: count);
    });

    // Default observeAll
    _catalogSub = db.foodCatalogDao.observeAll().listen((items) {
      _updateWith(foodCatalogItems: items.map(mapCatalogEntityToDomain).toList());
    });

    ref.onDispose(() {
      _goalSub?.cancel();
      _dataSub?.cancel();
      _allSub?.cancel();
      _templatesSub?.cancel();
      _loggedSub?.cancel();
      _favSub?.cancel();
      _recentSub?.cancel();
      _countSub?.cancel();
      _catalogSub?.cancel();
      _searchDebounce?.cancel();
    });

    return NutritionLoading();
  }

  NutritionContent get _content {
    if (state is NutritionContent) {
      return state as NutritionContent;
    }
    return NutritionContent(
      calorieLimit: 1800,
      caloriesEaten: 0,
      proteinEaten: 0,
      proteinLimit: 120,
      carbsEaten: 0,
      carbsLimit: 200,
      fatEaten: 0,
      fatLimit: 60,
      sweatActive: false,
      sweatExtraSets: 0,
      waterIntakeMl: 0,
      scanning: false,
    );
  }

  void _updateWith({
    ActiveGoal? activeGoal,
    NutritionData? nutritionData,
    List<NutritionDay>? allNutrition,
    List<MealTemplate>? mealTemplates,
    List<LoggedFoodData>? loggedFoods,
    List<FoodCatalogItem>? favorites,
    List<FoodCatalogItem>? recentFoods,
    int? foodCatalogCount,
    List<FoodCatalogItem>? foodCatalogItems,
    bool? scanning,
    Object? scanResult = _undefined,
    Object? scanError = _undefined,
    Object? draft = _undefined,
    bool? savingDraft,
    Object? pendingDeleteTemplateId = _undefined,
    Object? templateNameEdit = _undefined,
    String? searchQuery,
    Object? importSuccess = _undefined,
    Object? importErrorMessage = _undefined,
    List<String>? importWarnings,
    List<CartItem>? cart,
  }) {
    final current = _content;

    final goal = activeGoal ?? _cachedActiveGoal;
    // Fallback limit
    final fallbackLimit = () {
      final g = goal;
      switch (g?.config.goal) {
        case FitnessGoal.muscleGain:
          return 2400;
        case FitnessGoal.fatLossConditioning:
          return 1600;
        case FitnessGoal.endurance:
          return 2000;
        case FitnessGoal.generalFitness:
          return 1800;
        default:
          return 1800;
      }
    }();

    final today = currentLocalEpochDay();
    final todayDay = allNutrition?.firstOrNullWhere((e) => e.epochDay == today) ??
        current.history.firstOrNullWhere((e) => e.epochDay == today);
    final target = todayDay?.target;

    final proteinLimit = target?.proteinGrams ??
        () {
          final g = goal;
          switch (g?.config.goal) {
            case FitnessGoal.muscleGain:
              return (fallbackLimit * 0.30 / 4).round();
            case FitnessGoal.fatLossConditioning:
              return (fallbackLimit * 0.35 / 4).round();
            default:
              return (fallbackLimit * 0.25 / 4).round();
          }
        }();

    final fatLimit = target?.fatGrams ??
        () {
          final g = goal;
          switch (g?.config.goal) {
            case FitnessGoal.muscleGain:
              return (fallbackLimit * 0.25 / 9).round();
            case FitnessGoal.fatLossConditioning:
              return (fallbackLimit * 0.25 / 9).round();
            default:
              return (fallbackLimit * 0.25 / 9).round();
          }
        }();

    final carbsLimit = target?.carbsGrams ??
        () {
          final g = goal;
          switch (g?.config.goal) {
            case FitnessGoal.muscleGain:
              return (fallbackLimit * 0.45 / 4).round();
            case FitnessGoal.fatLossConditioning:
              return (fallbackLimit * 0.40 / 4).round();
            default:
              return (fallbackLimit * 0.50 / 4).round();
          }
        }();

    final eatenCals = nutritionData?.caloriesEaten ?? current.caloriesEaten;
    final eatenProt = nutritionData?.proteinEaten ?? current.proteinEaten;
    final eatenCarbs = nutritionData?.carbsEaten ?? current.carbsEaten;
    final eatenFat = nutritionData?.fatEaten ?? current.fatEaten;
    final eatenFiber = todayDay?.consumed.fiberGrams ?? current.fiberEaten;
    final water = todayDay?.waterIntakeMl ?? current.waterIntakeMl;

    final targetForScore = target ??
        NutritionTarget(
          basalCalories: fallbackLimit,
          maintenanceCalories: fallbackLimit,
          calories: fallbackLimit,
          proteinGrams: proteinLimit,
          carbsGrams: carbsLimit,
          fatGrams: fatLimit,
          audit: NutritionTargetAudit(
            rawBasalCalories: fallbackLimit.toDouble(),
            rawMaintenanceCalories: fallbackLimit.toDouble(),
            rawTargetCalories: fallbackLimit.toDouble(),
            rawProteinGrams: proteinLimit.toDouble(),
            rawCarbsGrams: carbsLimit.toDouble(),
            rawFatGrams: fatLimit.toDouble(),
          ),
        );

    final scoreResult = NutritionScoreCalculator.calculateScore(
      consumed: Nutrients(
        calories: eatenCals,
        proteinGrams: eatenProt,
        carbsGrams: eatenCarbs,
        fatGrams: eatenFat,
        fiberGrams: eatenFiber,
      ),
      target: targetForScore,
      waterIntakeMl: water,
    );

    final history = (allNutrition ?? current.history)
        .where((e) => e.epochDay < today && e.consumed.calories > 0)
        .toList();

    state = NutritionContent(
      calorieLimit: target?.calories ?? fallbackLimit,
      caloriesEaten: eatenCals,
      nutritionScore: scoreResult.score,
      nutritionScoreLabel: scoreResult.label,
      nutritionScoreEmoji: scoreResult.emoji,
      proteinEaten: eatenProt,
      proteinLimit: proteinLimit,
      carbsEaten: eatenCarbs,
      carbsLimit: carbsLimit,
      fatEaten: eatenFat,
      fatLimit: fatLimit,
      fiberEaten: eatenFiber,
      fiberLimit: 30,
      sweatActive: nutritionData?.sweatActive ?? current.sweatActive,
      sweatExerciseName: nutritionData?.sweatExerciseName ?? current.sweatExerciseName,
      sweatExtraSets: nutritionData?.sweatExtraSets ?? current.sweatExtraSets,
      waterIntakeMl: water,
      scanResult: scanResult == _undefined ? current.scanResult : (scanResult as ScanResult?),
      scanning: scanning ?? current.scanning,
      scanError: scanError == _undefined ? current.scanError : (scanError as String?),
      history: history,
      draft: draft == _undefined ? current.draft : (draft as EditableNutritionDraft?),
      mealTemplates: mealTemplates ?? current.mealTemplates,
      savingDraft: savingDraft ?? current.savingDraft,
      pendingDeleteTemplateId: pendingDeleteTemplateId == _undefined ? current.pendingDeleteTemplateId : (pendingDeleteTemplateId as int?),
      templateNameEdit: templateNameEdit == _undefined ? current.templateNameEdit : (templateNameEdit as TemplateNameEdit?),
      foodCatalogCount: foodCatalogCount ?? current.foodCatalogCount,
      foodCatalogItems: foodCatalogItems ?? current.foodCatalogItems,
      searchQuery: searchQuery ?? current.searchQuery,
      importSuccess: importSuccess == _undefined ? current.importSuccess : (importSuccess as bool?),
      importErrorMessage: importErrorMessage == _undefined ? current.importErrorMessage : (importErrorMessage as String?),
      importWarnings: importWarnings ?? current.importWarnings,
      cart: cart ?? current.cart,
      loggedFoods: loggedFoods ?? current.loggedFoods,
      favorites: favorites ?? current.favorites,
      recentFoods: recentFoods ?? current.recentFoods,
    );
  }

  Future<void> scanBarcode(String barcode) async {
    _scannedBarcode = barcode;
    _updateWith(
      scanning: true,
      scanError: null,
      scanResult: null,
      draft: null,
    );

    try {
      final result = await ref.read(barcodeRepositoryProvider).lookup(barcode);
      if (result != null) {
        _draftSweatPayment = result.sweatPayment;
        _draftNutrientsRecorded = false;
        
        _updateWith(
          scanning: false,
          scanResult: result,
          draft: EditableNutritionDraft(
            nameVi: result.dishName,
            caloriesText: result.totalCalories.toString(),
            proteinText: result.proteinGrams.toString(),
            carbsText: result.carbsGrams.toString(),
            fatText: result.fatGrams.toString(),
            fiberText: "0",
            saveAsTemplate: false,
            errors: const {},
          ),
        );
      } else {
        _draftSweatPayment = null;
        _draftNutrientsRecorded = false;

        _updateWith(
          scanning: false,
          draft: EditableNutritionDraft(
            nameVi: "",
            caloriesText: "",
            proteinText: "",
            carbsText: "",
            fatText: "",
            fiberText: "0",
            saveAsTemplate: false,
            errors: {"submit": "Không tìm thấy sản phẩm. Vui lòng nhập thông tin để đăng ký mã vạch này."},
          ),
        );
      }
    } catch (e) {
      _updateWith(
        scanning: false,
        scanError: "Lỗi kết nối tới server: $e",
      );
    }
  }

  void acceptScanResult() {
    acceptDraft();
  }

  void startManualEntry() {
    if (_content.savingDraft) return;
    _draftSweatPayment = null;
    _draftNutrientsRecorded = false;
    _updateWith(
      draft: EditableNutritionDraft(errors: const {}),
    );
  }

  void selectScanRecommendation(ScanRecommendation recommendation) {
    final result = _content.scanResult;
    if (result == null) return;
    _draftSweatPayment = result.sweatPayment;
    _draftNutrientsRecorded = false;

    _updateWith(
      draft: EditableNutritionDraft(
        nameVi: recommendation.dishName,
        caloriesText: recommendation.calories.toString(),
        proteinText: recommendation.proteinGrams.toString(),
        carbsText: recommendation.carbsGrams.toString(),
        fatText: recommendation.fatGrams.toString(),
        fiberText: "0",
        saveAsTemplate: false,
        errors: const {},
      ),
      scanResult: null, // Clear scan result once selected
    );
  }

  void updateDraftName(String value) {
    _updateDraft((d) => d.copyWith(nameVi: value, errors: const {}));
  }

  void updateDraftCalories(String value) {
    _updateDraft((d) => d.copyWith(caloriesText: value, errors: const {}));
  }

  void updateDraftProtein(String value) {
    _updateDraft((d) => d.copyWith(proteinText: value, errors: const {}));
  }

  void updateDraftCarbs(String value) {
    _updateDraft((d) => d.copyWith(carbsText: value, errors: const {}));
  }

  void updateDraftFat(String value) {
    _updateDraft((d) => d.copyWith(fatText: value, errors: const {}));
  }

  void updateDraftFiber(String value) {
    _updateDraft((d) => d.copyWith(fiberText: value, errors: const {}));
  }

  void setDraftSaveAsTemplate(bool value) {
    _updateDraft((d) => d.copyWith(saveAsTemplate: value));
  }

  Future<void> acceptDraft() async {
    final draft = _content.draft;
    if (draft == null || _content.savingDraft) return;

    final parsed = _validateAndParse(draft);
    if (parsed.errors.isNotEmpty) {
      _updateWith(draft: draft.copyWith(errors: parsed.errors));
      return;
    }

    final nutrients = parsed.nutrients!;
    final normalizedName = draft.nameVi.trim();
    final sweatPayment = _draftSweatPayment;

    _updateWith(savingDraft: true);

    try {
      final currentBarcode = _scannedBarcode;
      if (currentBarcode != null) {
        final result = ScanResult(
          dishName: normalizedName,
          totalCalories: nutrients.calories,
          proteinGrams: nutrients.proteinGrams,
          carbsGrams: nutrients.carbsGrams,
          fatGrams: nutrients.fatGrams,
          fitnessScore: 5,
          advice: "Sản phẩm đóng gói dạng quét mã vạch.",
          constituents: const [],
          sweatPayment: sweatPayment,
          calculationProcess: "Đăng ký từ thiết bị người dùng.",
          confidence: 1.0,
          needsUserConfirmation: false,
          recommendations: const [],
        );
        try {
          await ref.read(barcodeRepositoryProvider).saveOverride(
                currentBarcode,
                result,
              );
        } catch (_) {}
        _scannedBarcode = null;
      }

      if (!_draftNutrientsRecorded) {
        final hour = DateTime.now().hour;
        final mealTime = () {
          if (hour < 10) return "BREAKFAST";
          if (hour < 14) return "LUNCH";
          if (hour < 17) return "SNACK";
          return "DINNER";
        }();

        await ref.read(nutritionRepositoryProvider).logFood(
          epochDay: currentLocalEpochDay(),
          name: normalizedName,
          mealTime: mealTime,
          grams: 100.0,
          calories: nutrients.calories,
          proteinGrams: nutrients.proteinGrams,
          carbsGrams: nutrients.carbsGrams,
          fatGrams: nutrients.fatGrams,
          fiberGrams: nutrients.fiberGrams,
          foodCatalogId: null,
        );

        if (sweatPayment != null) {
          await ref.read(nutritionRepositoryProvider).setSweatPayment(
            sweatPayment.exerciseId,
            sweatPayment.exerciseName,
            sweatPayment.extraSets,
            true,
          );
        }
        _draftNutrientsRecorded = true;
      }

      if (draft.saveAsTemplate) {
        await ref.read(nutritionRepositoryProvider).saveMealTemplate(
          null,
          normalizedName,
          nutrients,
        );
      }

      _scannedBarcode = null;
      _draftSweatPayment = null;
      _draftNutrientsRecorded = false;
      _updateWith(
        draft: null,
        savingDraft: false,
        scanResult: null,
      );
    } catch (_) {
      _updateWith(
        savingDraft: false,
        draft: draft.copyWith(
          errors: {"submit": "Không thể lưu món ăn. Vui lòng thử lại."},
        ),
      );
    }
  }

  void discardScanResult() {
    _scannedBarcode = null;
    _draftSweatPayment = null;
    _draftNutrientsRecorded = false;
    _updateWith(
      scanResult: null,
      draft: null,
    );
  }

  Future<void> applyTemplate(int id) async {
    if (_content.savingDraft) return;
    _updateWith(savingDraft: true);

    try {
      await ref.read(nutritionRepositoryProvider).applyMealTemplate(
        id,
        currentLocalEpochDay(),
      );
      _updateWith(savingDraft: false);
    } catch (_) {
      _updateWith(
        savingDraft: false,
        scanError: "Không thể thêm bữa ăn đã lưu. Vui lòng thử lại.",
      );
    }
  }

  void requestDeleteTemplate(int id) {
    if (!_content.savingDraft) {
      _updateWith(pendingDeleteTemplateId: id);
    }
  }

  void cancelDeleteTemplate() {
    if (!_content.savingDraft) {
      _updateWith(pendingDeleteTemplateId: null);
    }
  }

  Future<void> confirmDeleteTemplate() async {
    final id = _content.pendingDeleteTemplateId;
    if (id == null || _content.savingDraft) return;

    _updateWith(
      pendingDeleteTemplateId: null,
      savingDraft: true,
    );

    try {
      await ref.read(nutritionRepositoryProvider).deleteMealTemplate(id);
      _updateWith(savingDraft: false);
    } catch (_) {
      _updateWith(
        savingDraft: false,
        scanError: "Không thể xóa bữa ăn đã lưu. Vui lòng thử lại.",
      );
    }
  }

  void startRenameTemplate(int id) {
    if (_content.savingDraft) return;
    final template = _content.mealTemplates.firstOrNullWhere((e) => e.id == id);
    if (template != null) {
      _updateWith(
        templateNameEdit: TemplateNameEdit(id: id, nameVi: template.nameVi),
      );
    }
  }

  void updateTemplateName(String value) {
    if (!_content.savingDraft) {
      final currentEdit = _content.templateNameEdit;
      if (currentEdit != null) {
        _updateWith(
          templateNameEdit: currentEdit.copyWith(nameVi: value, error: null),
        );
      }
    }
  }

  void cancelRenameTemplate() {
    if (!_content.savingDraft) {
      _updateWith(templateNameEdit: null);
    }
  }

  Future<void> confirmRenameTemplate() async {
    final edit = _content.templateNameEdit;
    if (edit == null || _content.savingDraft) return;

    final template = _content.mealTemplates.firstOrNullWhere((e) => e.id == edit.id);
    if (template == null) return;

    final normalized = edit.nameVi.trim();
    if (normalized.isEmpty || normalized.length > 60) {
      _updateWith(
        templateNameEdit: edit.copyWith(error: "Tên món cần từ 1 đến 60 ký tự."),
      );
      return;
    }

    _updateWith(savingDraft: true);

    try {
      await ref.read(nutritionRepositoryProvider).saveMealTemplate(
        template.id,
        normalized,
        template.nutrients,
      );
      _updateWith(
        templateNameEdit: null,
        savingDraft: false,
      );
    } catch (_) {
      _updateWith(
        savingDraft: false,
        templateNameEdit: edit.copyWith(error: "Không thể đổi tên. Vui lòng thử lại."),
      );
    }
  }

  void updateScanResult({
    required String dishName,
    required int totalCalories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
  }) {
    final current = _content.scanResult;
    if (current == null) return;

    _updateWith(
      scanResult: current.copyWith(
        dishName: dishName,
        totalCalories: totalCalories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
      ),
    );
  }

  Future<void> addWater(int waterMl) async {
    await ref.read(nutritionRepositoryProvider).addWater(
      currentLocalEpochDay(),
      waterMl,
    );
  }

  Future<void> clearSweat() async {
    await ref.read(nutritionRepositoryProvider).clearSweatPayment();
  }

  Future<void> resetDaily() async {
    await ref.read(nutritionRepositoryProvider).resetDaily();
  }

  void searchFoodsCatalog(String query) {
    _updateWith(searchQuery: query);
    _searchDebounce?.cancel();
    
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _catalogSub?.cancel();
      final db = ref.read(gymDatabaseProvider);
      final stream = query.isEmpty
          ? db.foodCatalogDao.observeAll()
          : db.foodCatalogDao.searchByName(query);

      _catalogSub = stream.listen((items) {
        _updateWith(foodCatalogItems: items.map(mapCatalogEntityToDomain).toList());
      });
    });
  }

  Future<void> clearFoodCatalog() async {
    final db = ref.read(gymDatabaseProvider);
    _updateWith(
      importSuccess: null,
      importErrorMessage: null,
      importWarnings: const [],
      searchQuery: "",
    );
    try {
      await db.foodCatalogDao.deleteAll();
    } catch (_) {}
  }

  Future<void> addFoodFromCatalog(FoodCatalogItem food, double servingGrams) async {
    try {
      final factor = servingGrams / food.gramsPerServing;
      final calories = (food.caloriesPerServing * factor).round();
      final protein = (food.proteinPerServing * factor).round();
      final carbs = (food.carbsPerServing * factor).round();
      final fat = (food.fatPerServing * factor).round();
      final fiber = (food.fiberPerServing * factor).round();

      final hour = DateTime.now().hour;
      final mealTime = () {
        if (hour < 10) return "BREAKFAST";
        if (hour < 14) return "LUNCH";
        if (hour < 17) return "SNACK";
        return "DINNER";
      }();

      await ref.read(nutritionRepositoryProvider).logFood(
        epochDay: currentLocalEpochDay(),
        name: food.name,
        mealTime: mealTime,
        grams: servingGrams,
        calories: calories,
        proteinGrams: protein,
        carbsGrams: carbs,
        fatGrams: fat,
        fiberGrams: fiber,
        foodCatalogId: food.id,
      );
    } catch (_) {}
  }

  void addToCart(FoodCatalogItem food, double grams, String mealTime) {
    final currentList = List<CartItem>.from(_content.cart);
    final existingIndex = currentList.indexWhere((e) => e.food.id == food.id && e.mealTime == mealTime);
    if (existingIndex >= 0) {
      final existing = currentList[existingIndex];
      currentList[existingIndex] = existing.copyWith(grams: existing.grams + grams);
    } else {
      currentList.add(CartItem(food: food, grams: grams, mealTime: mealTime));
    }
    _updateWith(cart: currentList);
  }

  void removeFromCart(int foodCatalogId, String mealTime) {
    final currentList = List<CartItem>.from(_content.cart)
      ..removeWhere((e) => e.food.id == foodCatalogId && e.mealTime == mealTime);
    _updateWith(cart: currentList);
  }

  void updateCartGrams(int foodCatalogId, String mealTime, double grams) {
    final currentList = List<CartItem>.from(_content.cart);
    final index = currentList.indexWhere((e) => e.food.id == foodCatalogId && e.mealTime == mealTime);
    if (index >= 0) {
      currentList[index] = currentList[index].copyWith(grams: grams);
    }
    _updateWith(cart: currentList);
  }

  void clearCart() {
    _updateWith(cart: const []);
  }

  Future<void> confirmEatCart() async {
    final cart = _content.cart;
    if (cart.isEmpty) return;

    try {
      final today = currentLocalEpochDay();
      final entries = cart.map((item) {
        final factor = item.grams / item.food.gramsPerServing;
        return FoodLogEntry(
          name: item.food.name,
          mealTime: item.mealTime,
          grams: item.grams,
          calories: (item.food.caloriesPerServing * factor).round(),
          proteinGrams: (item.food.proteinPerServing * factor).round(),
          carbsGrams: (item.food.carbsPerServing * factor).round(),
          fatGrams: (item.food.fatPerServing * factor).round(),
          fiberGrams: (item.food.fiberPerServing * factor).round(),
          foodCatalogId: item.food.id > 0 ? item.food.id : null,
        );
      }).toList();

      await ref
          .read(nutritionRepositoryProvider)
          .logFoods(epochDay: today, entries: entries);
      _updateWith(cart: const []);
    } catch (_) {}
  }

  Future<void> toggleFavoriteCatalog(int id, bool isFavorite) async {
    await ref.read(nutritionRepositoryProvider).toggleFavorite(id, isFavorite);
  }

  Future<void> deleteLoggedFood(int id) async {
    await ref.read(nutritionRepositoryProvider).deleteLoggedFood(id);
  }

  Future<void> copyYesterdayMeals() async {
    final today = currentLocalEpochDay();
    await ref.read(nutritionRepositoryProvider).copyYesterdayMeals(
      today - 1,
      today,
    );
  }

  Future<void> importNutritionFromCsv(String csvText) async {
    await importNutritionFile("import.csv", Uint8List.fromList(csvText.codeUnits));
  }

  Future<void> importNutritionFile(String fileName, List<int> fileData) async {
    final db = ref.read(gymDatabaseProvider);
    _updateWith(
      importSuccess: null,
      importErrorMessage: null,
      importWarnings: const [],
    );

    try {
      final batchId = DateTime.now().millisecondsSinceEpoch.toString();
      final parseResult = await Isolate.run(() {
        if (fileName.toLowerCase().endsWith(".xlsx")) {
          return NutritionXlsxParser.parse(Uint8List.fromList(fileData), batchId: batchId);
        } else {
          final csvText = String.fromCharCodes(fileData);
          return NutritionCsvParser.parse(csvText, batchId: batchId);
        }
      });

      if (parseResult.items.isEmpty) {
        _updateWith(
          importSuccess: false,
          importErrorMessage: parseResult.warnings.firstOrNull ?? "Tệp trống hoặc không đúng cấu trúc.",
        );
      } else {
        await db.foodCatalogDao.insertAll(parseResult.items.map(mapDomainToCatalogData).toList());
        _updateWith(
          importSuccess: true,
          importWarnings: parseResult.warnings,
        );
        // Refresh catalog view with empty search query
        searchFoodsCatalog("");
      }
    } catch (e) {
      _updateWith(
        importSuccess: false,
        importErrorMessage: "Lỗi xử lý file: $e",
      );
    }
  }

  Future<List<int>> exportFoodCatalogToXlsx() async {
    final db = ref.read(gymDatabaseProvider);
    final items = await db.foodCatalogDao.getAllNow();
    final domainItems = items.map(mapCatalogEntityToDomain).toList();
    return NutritionXlsxWriter.write(domainItems);
  }

  void _updateDraft(EditableNutritionDraft Function(EditableNutritionDraft) transform) {
    if (_content.savingDraft) return;
    final currentDraft = _content.draft;
    if (currentDraft != null) {
      _updateWith(draft: transform(currentDraft));
    }
  }

  ParsedDraft _validateAndParse(EditableNutritionDraft draft) {
    final errors = <String, String>{};
    final normalizedName = draft.nameVi.trim();
    if (normalizedName.isEmpty || normalizedName.length > 60) {
      errors["nameVi"] = "Tên món cần từ 1 đến 60 ký tự.";
    }

    int? parseField(String field, String raw) {
      final cleaned = raw.trim().replaceAll(',', '.');
      final doubleValue = double.tryParse(cleaned);
      if (doubleValue == null || doubleValue < 0.0) {
        errors[field] = "Nhập số không âm.";
        return null;
      }
      return doubleValue.round();
    }

    final calories = parseField("calories", draft.caloriesText);
    final protein = parseField("protein", draft.proteinText);
    final carbs = parseField("carbs", draft.carbsText);
    final fat = parseField("fat", draft.fatText);
    final fiberTextOrZero = draft.fiberText.trim().isEmpty ? "0" : draft.fiberText;
    final fiber = parseField("fiber", fiberTextOrZero);

    if (calories != null && calories <= 0) {
      errors["calories"] = "Calo phải lớn hơn 0.";
    }

    return ParsedDraft(
      nutrients: errors.isEmpty
          ? Nutrients(
              calories: calories!,
              proteinGrams: protein!,
              carbsGrams: carbs!,
              fatGrams: fat!,
              fiberGrams: fiber!,
            )
          : null,
      errors: errors,
    );
  }
}

class ParsedDraft {
  final Nutrients? nutrients;
  final Map<String, String> errors;
  ParsedDraft({required this.nutrients, required this.errors});
}

final nutritionNotifierProvider = NotifierProvider<NutritionNotifier, NutritionUiState>(
  NutritionNotifier.new,
);

extension IterableExtensions<T> on Iterable<T> {
  T? firstOrNullWhere(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
