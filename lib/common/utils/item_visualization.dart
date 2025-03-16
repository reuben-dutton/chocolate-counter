import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_inventory/common/services/config_service.dart';

class ItemVisualization {
  // Comprehensive list of food-related icons from Material and Font Awesome
  static final List<IconData> foodIcons = [
    // Material Icons
    Icons.restaurant_menu,
    Icons.fastfood,
    Icons.lunch_dining,
    Icons.bakery_dining,
    Icons.coffee,
    Icons.icecream,
    Icons.local_pizza,
    Icons.local_cafe,
    Icons.egg,
    Icons.dinner_dining,
    Icons.ramen_dining,
    Icons.kebab_dining,
    Icons.set_meal,
    Icons.bento,
    Icons.kitchen,
    Icons.wine_bar,
    Icons.cake,

    // Font Awesome Icons - Broad Food Categories
    FontAwesomeIcons.breadSlice,
    FontAwesomeIcons.burger,
    FontAwesomeIcons.pizzaSlice,
    FontAwesomeIcons.utensils,
    FontAwesomeIcons.cheese,
    FontAwesomeIcons.apple,
    FontAwesomeIcons.carrot,
    FontAwesomeIcons.cookieBite,
    FontAwesomeIcons.wineBottle,
    FontAwesomeIcons.fishFins,

    // More Specific Food Items
    FontAwesomeIcons.seedling,
    FontAwesomeIcons.candyCane,
    FontAwesomeIcons.bacon,
    FontAwesomeIcons.egg,
    FontAwesomeIcons.lemon,
    FontAwesomeIcons.pepperHot,
    FontAwesomeIcons.mugHot,
    FontAwesomeIcons.shrimp,
    FontAwesomeIcons.fish,

    // Kitchen and Cooking
    FontAwesomeIcons.bowlFood,
    FontAwesomeIcons.bottleWater,
    FontAwesomeIcons.wheatAwn,
    FontAwesomeIcons.iceCream,
    FontAwesomeIcons.martiniGlass,
  ];
  
  // List of theme-derived colors with variations
  static List<Color> getEarthyColors(BuildContext context) {
    final theme = Theme.of(context);
    return [
      theme.colorScheme.secondary..withAlpha(ConfigService.alphaHigh),
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.tertiary..withAlpha(ConfigService.alphaHigh),
      theme.colorScheme.tertiaryContainer,
    ];
  }
  
  // Get a consistent icon for a given item name
  static IconData getIconForItem(String itemName) {
    final int nameHash = itemName.hashCode.abs();
    final int iconIndex = nameHash % foodIcons.length;
    return foodIcons[iconIndex];
  }
  
  // Get a consistent color for a given item name
  static Color getColorForItem(String itemName, BuildContext context) {
    final List<Color> colors = getEarthyColors(context);
    final int nameHash = itemName.hashCode.abs();
    final int colorIndex = (nameHash ~/ 10) % colors.length;
    return colors[colorIndex];
  }
}