import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_inventory/common/services/config_service.dart';
import 'package:food_inventory/data/repositories/inventory_movement_repository.dart';
import 'package:food_inventory/data/repositories/item_definition_repository.dart';
import 'package:food_inventory/data/repositories/item_instance_repository.dart';
import 'package:food_inventory/data/repositories/shipment_repository.dart';
import 'package:food_inventory/features/export/bloc/export_bloc.dart';
import 'package:food_inventory/features/export/models/export_mode.dart';
import 'package:provider/provider.dart';

class ExportSummary extends StatefulWidget {
  const ExportSummary({super.key});

  @override
  State<ExportSummary> createState() => _ExportSummaryState();
}

class _ExportSummaryState extends State<ExportSummary> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use repositories to get counts instead of direct database access
      final itemDefRepository = Provider.of<ItemDefinitionRepository>(context, listen: false);
      final itemInstanceRepository = Provider.of<ItemInstanceRepository>(context, listen: false);
      final shipmentRepository = Provider.of<ShipmentRepository>(context, listen: false);
      final movementRepository = Provider.of<InventoryMovementRepository>(context, listen: false);
      
      // Use transactions for consistent reads
      await itemDefRepository.withTransaction((txn) async {
        // Get item definitions count
        final itemDefs = await itemDefRepository.getAllSorted(txn: txn);
        
        // Count item definitions with images
        final imagesCount = itemDefs.where((def) => def.imageUrl != null).length;
        
        // Get shipments count
        final shipments = await shipmentRepository.getAllWithItems(txn: txn);
        
        // Get stock and inventory counts
        int stockCount = 0;
        int inventoryCount = 0;
        int itemInstancesCount = 0;
        
        // Get all unique item definition IDs
        final itemDefIds = itemDefs.map((def) => def.id!).toList();
        
        // Get counts for each item definition
        for (final id in itemDefIds) {
          final counts = await itemInstanceRepository.getItemCounts(id, txn: txn);
          stockCount += counts['stock'] ?? 0;
          inventoryCount += counts['inventory'] ?? 0;
          
          // Get instances for this item to count total instances
          final instances = await itemInstanceRepository.getInstancesForItem(id, txn: txn);
          itemInstancesCount += instances.length;
        }
        
        // Get all movements to count them
        int movementsCount = 0;
        for (final id in itemDefIds) {
          final movements = await movementRepository.getMovementsForItem(id, txn: txn);
          movementsCount += movements.length;
        }
        
        setState(() {
          _stats = {
            'itemDefinitions': itemDefs.length,
            'itemInstances': itemInstancesCount,
            'shipments': shipments.length,
            'movements': movementsCount,
            'stockCount': stockCount,
            'inventoryCount': inventoryCount,
            'imagesCount': imagesCount,
          };
          _isLoading = false;
        });
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<ExportBloc, ExportState>(
      buildWhen: (previous, current) => 
        previous is! ExportConfigured || 
        current is! ExportConfigured ||
        (previous as ExportConfigured).mode != (current as ExportConfigured).mode ||
        (previous as ExportConfigured).includeImages != (current as ExportConfigured).includeImages ||
        (previous as ExportConfigured).outputDirectory != (current as ExportConfigured).outputDirectory,
      builder: (context, state) {
        // Get export configuration from bloc state
        final exportMode = state is ExportConfigured ? state.mode : null;
        final includeImages = state is ExportConfigured ? state.includeImages : false;
        final outputDirectory = state is ExportConfigured ? state.outputDirectory : null;
        
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Export configuration summary
              _buildConfigurationCard(theme, exportMode, includeImages, outputDirectory),
              
              // Database statistics
              _buildContentSummaryCard(theme, includeImages),
              
              // Export format information
              _buildFormatDetailsCard(theme, exportMode, includeImages),
              
              // Ready to export
              _buildReadinessCard(theme, exportMode, outputDirectory),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigurationCard(ThemeData theme, ExportMode? exportMode, bool includeImages, String? outputDirectory) {
    return Card(
      margin: EdgeInsets.all(ConfigService.smallPadding),
      child: Padding(
        padding: EdgeInsets.all(ConfigService.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, size: ConfigService.mediumIconSize, color: theme.colorScheme.primary),
                SizedBox(width: ConfigService.smallPadding),
                Text(
                  'Export Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildConfigRow(
              context, 
              'Export Format:', 
              exportMode?.displayName ?? 'Not selected',
              exportMode?.icon ?? Icons.question_mark,
              exportMode != null ? theme.colorScheme.primary : theme.colorScheme.error,
            ),
            SizedBox(height: ConfigService.smallPadding),
            _buildConfigRow(
              context, 
              'Include Images:', 
              includeImages ? 'Yes' : 'No',
              includeImages ? Icons.check_circle_outline : Icons.cancel_outlined,
              includeImages ? Colors.green : Colors.grey,
            ),
            SizedBox(height: ConfigService.smallPadding),
            _buildConfigRow(
              context, 
              'Export Location:', 
              outputDirectory != null ? _formatDirectory(outputDirectory) : 'Not selected',
              Icons.folder,
              outputDirectory != null ? theme.colorScheme.primary : theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSummaryCard(ThemeData theme, bool includeImages) {
    return Card(
      margin: EdgeInsets.all(ConfigService.smallPadding),
      child: Padding(
        padding: EdgeInsets.all(ConfigService.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, size: ConfigService.mediumIconSize, color: theme.colorScheme.primary),
                SizedBox(width: ConfigService.smallPadding),
                Text(
                  'Export Content Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDataRow(context, 'Item Definitions:', _stats['itemDefinitions'] ?? 0),
            SizedBox(height: ConfigService.tinyPadding),
            _buildDataRow(context, 'Item Instances:', _stats['itemInstances'] ?? 0),
            SizedBox(height: ConfigService.tinyPadding),
            _buildDataRow(context, 'Shipments:', _stats['shipments'] ?? 0),
            SizedBox(height: ConfigService.tinyPadding),
            _buildDataRow(context, 'Movement Records:', _stats['movements'] ?? 0),
            SizedBox(height: ConfigService.tinyPadding),
            _buildDataRow(context, 'Images:', _stats['imagesCount'] ?? 0, highlight: includeImages),
            const Divider(),
            _buildDataRow(context, 'Total Stock Items:', _stats['stockCount'] ?? 0, isSummary: true),
            SizedBox(height: ConfigService.tinyPadding),
            _buildDataRow(context, 'Total Inventory Items:', _stats['inventoryCount'] ?? 0, isSummary: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatDetailsCard(ThemeData theme, ExportMode? exportMode, bool includeImages) {
    return Card(
      margin: EdgeInsets.all(ConfigService.smallPadding),
      child: Padding(
        padding: EdgeInsets.all(ConfigService.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(exportMode?.icon ?? Icons.info_outline, size: ConfigService.mediumIconSize, color: theme.colorScheme.primary),
                SizedBox(width: ConfigService.smallPadding),
                Text(
                  'Export Format Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(exportMode?.description ?? 'Please select an export format.'),
            SizedBox(height: ConfigService.mediumPadding),
            _buildFormatSpecificDetails(exportMode, includeImages),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessCard(ThemeData theme, ExportMode? exportMode, String? outputDirectory) {
    final isExportReady = exportMode != null && outputDirectory != null;
    final missingItems = _getMissingConfigurationItems(exportMode, outputDirectory);
    
    return Card(
      color: theme.colorScheme.primaryContainer,
      margin: EdgeInsets.all(ConfigService.smallPadding),
      child: Padding(
        padding: EdgeInsets.all(ConfigService.defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isExportReady ? Icons.check_circle : Icons.warning,
                  size: ConfigService.defaultIconSize, 
                  color: isExportReady ? theme.colorScheme.primary : theme.colorScheme.error
                ),
                SizedBox(width: ConfigService.smallPadding),
                Expanded(
                  child: Text(
                    isExportReady 
                        ? 'Your export is ready to be created'
                        : 'Please complete all export settings before continuing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isExportReady ? theme.colorScheme.primary : theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ConfigService.smallPadding),
            if (!isExportReady)
              ...missingItems.map(
                (item) => Padding(
                  padding: EdgeInsets.only(left: ConfigService.mediumPadding),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: ConfigService.smallIconSize, color: theme.colorScheme.error),
                      SizedBox(width: ConfigService.smallPadding),
                      Text(item, style: TextStyle(color: theme.colorScheme.error)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: ConfigService.smallIconSize, color: iconColor),
        SizedBox(width: ConfigService.smallPadding),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(ConfigService.alphaHigh),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(BuildContext context, String label, int count, {bool isSummary = false, bool highlight = false}) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSummary ? 14 : 13,
              fontWeight: isSummary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: ConfigService.smallPadding, vertical: 2),
          decoration: BoxDecoration(
            color: highlight ? theme.colorScheme.primary.withAlpha(ConfigService.alphaLight) : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ConfigService.borderRadiusSmall),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSpecificDetails(ExportMode? exportMode, bool includeImages) {
    if (exportMode == null) {
      return const SizedBox.shrink();
    }
    
    // Details specific to each export format
    switch (exportMode) {
      case ExportMode.csv:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CSV Export will include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ConfigService.tinyPadding),
            Text('• Separate CSV files for each data table'),
            Text('• Data format suitable for spreadsheet applications'),
            Text('• UTF-8 encoding with comma delimiters'),
            if (includeImages)
              Text('• Original item images in a separate folder'),
          ],
        );
        
      case ExportMode.excel:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Excel Export will include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ConfigService.tinyPadding),
            Text('• Single Excel file with multiple worksheets'),
            Text('• One worksheet per data table'),
            Text('• Additional worksheet for enum references'),
            if (includeImages)
              Text('• Original item images in a separate folder'),
          ],
        );
        
      case ExportMode.sqlite:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SQLite Export will include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ConfigService.tinyPadding),
            Text('• Complete SQLite database file'),
            Text('• All tables, indices, and data'),
            Text('• Compatible with most SQLite browsers'),
            if (includeImages)
              Text('• Original item images in a separate folder'),
          ],
        );
        
      case ExportMode.json:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JSON Export will include:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ConfigService.tinyPadding),
            Text('• Separate JSON files for each data table'),
            Text('• Data in standard JSON format'),
            Text('• Suitable for programmatic processing'),
            if (includeImages)
              Text('• Original item images in a separate folder'),
          ],
        );
    }
  }

  List<String> _getMissingConfigurationItems(ExportMode? exportMode, String? outputDirectory) {
    final List<String> missing = [];
    
    if (exportMode == null) {
      missing.add('Export format is not selected');
    }
    
    if (outputDirectory == null) {
      missing.add('Export destination folder is not selected');
    }
    
    return missing;
  }

  String _formatDirectory(String dir) {
    if (dir.length > 30) {
      // Show just the beginning and end of the path
      return '${dir.substring(0, 10)}...${dir.substring(dir.length - 15)}';
    }
    return dir;
  }
}