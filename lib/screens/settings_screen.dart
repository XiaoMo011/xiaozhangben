import 'package:flutter/material.dart';
import '../data/categories.dart';

/// 设置页面 - 分类管理、预算设置、数据导出、关于
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: ListView(
        children: [
          // 分类管理
          _buildSectionHeader(theme, '分类管理'),
          ListTile(
            leading: Icon(Icons.category,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('管理支出分类'),
            subtitle: Text(
                '共${defaultCategories.length}个大类，可添加、重命名或隐藏'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CategoryManageScreen()),
              );
            },
          ),
          const Divider(),

          // 预算设置
          _buildSectionHeader(theme, '预算'),
          ListTile(
            leading: Icon(Icons.savings,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('月度预算'),
            subtitle: const Text('设置每月支出上限，超支时提醒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('预算功能将在后续版本推出')),
              );
            },
          ),
          const Divider(),

          // 数据
          _buildSectionHeader(theme, '数据'),
          ListTile(
            leading: Icon(Icons.file_download,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('导出数据'),
            subtitle: const Text('导出为CSV文件（后续版本推出）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导出功能将在后续版本推出')),
              );
            },
          ),
          const Divider(),

          // 关于
          _buildSectionHeader(theme, '关于'),
          ListTile(
            leading: Icon(Icons.info_outline,
                color: theme.colorScheme.onSurfaceVariant),
            title: const Text('关于小账本'),
            subtitle: const Text('版本 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '小账本',
                applicationVersion: '1.0.0',
                applicationLegalese: '个人记账工具\n数据完全保存在您的设备上',
                children: [
                  const Text('一款简单、快速、无需学习的个人记账App。'),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 分类管理页面（占位 - 后续完善）
class CategoryManageScreen extends StatelessWidget {
  const CategoryManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理支出分类'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: defaultCategories.length,
        itemBuilder: (context, index) {
          final major = defaultCategories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: Icon(Icons.folder, color: theme.colorScheme.primary),
              title: Text(major.name,
                  style: theme.textTheme.titleMedium),
              subtitle: Text('${major.subCategories.length}个子分类'),
              children: major.subCategories.map((sub) {
                return ListTile(
                  title: Text(sub.name),
                  leading: const Icon(Icons.label_outline, size: 20),
                  dense: true,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
