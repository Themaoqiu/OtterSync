import 'package:flutter/material.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

abstract final class JiraDemoData {
  static const homeQuickAccess = [
    QuickAccessItem(
      title: '利用人工智能创建工作项',
      subtitle: '上传图像',
      icon: Icons.photo_camera_outlined,
      color: Color(0xFFE9D5FF),
      badge: '测试版',
    ),
    QuickAccessItem(
      title: '我的工作',
      subtitle: '筛选器',
      icon: Icons.filter_alt_outlined,
      color: Color(0xFFD8E7FF),
    ),
    QuickAccessItem(
      title: '使用毛球',
      subtitle: 'OT-2 • ottersync',
      icon: Icons.task_alt_rounded,
      color: Color(0xFFD8E7FF),
    ),
    QuickAccessItem(
      title: 'ottersync',
      subtitle: '空间',
      icon: Icons.thunderstorm_rounded,
      color: Color(0xFFD9CCFF),
      route: '/space-details',
    ),
    QuickAccessItem(
      title: 'OT面板',
      subtitle: 'ottersync',
      icon: Icons.view_week_outlined,
      color: Color(0xFFE9D5FF),
      route: '/space-details',
    ),
  ];

  static const recentProjects = [
    JiraIssueSummary(
      title: '使用毛球',
      key: 'OT-2',
      subtitle: 'ottersync',
      icon: Icons.task_alt_rounded,
      iconBackgroundColor: Color(0xFFD8E7FF),
      iconColor: Color(0xFF0C66E4),
    ),
    JiraIssueSummary(
      title: '我的打开事务',
      key: '筛选器',
      subtitle: '已查看',
      icon: Icons.filter_alt_rounded,
      iconBackgroundColor: Color(0xFFD8E7FF),
      iconColor: Color(0xFF0C66E4),
    ),
    JiraIssueSummary(
      title: 'OT面板',
      key: '面板',
      subtitle: 'ottersync 内',
      icon: Icons.view_week_outlined,
      iconBackgroundColor: Color(0xFFE9D5FF),
      iconColor: Color(0xFF8E4BC3),
    ),
    JiraIssueSummary(
      title: '测试任务1',
      key: 'OT-1',
      subtitle: 'ottersync',
      icon: Icons.task_alt_rounded,
      iconBackgroundColor: Color(0xFFD8E7FF),
      iconColor: Color(0xFF0C66E4),
    ),
  ];

  static const spaces = [JiraSpace(name: 'ottersync', key: 'OT')];

  static const summaryMetrics = [
    SpaceSummaryMetric(
      headline: '过去 7 天内',
      value: '0',
      icon: Icons.check_rounded,
      color: Color(0xFF111214),
      emphasis: '项已完成',
    ),
    SpaceSummaryMetric(
      headline: '在过去 7 天内',
      value: '2',
      icon: Icons.edit_outlined,
      color: Color(0xFF123A86),
      emphasis: '项已更新',
    ),
    SpaceSummaryMetric(
      headline: '在过去 7 天内',
      value: '2',
      icon: Icons.add_rounded,
      color: Color(0xFF8E4BC3),
      emphasis: '项已创建',
    ),
    SpaceSummaryMetric(
      headline: '未来 7 天内',
      value: '0',
      icon: Icons.calendar_today_outlined,
      color: Color(0xFF111214),
      emphasis: '项已到期',
    ),
  ];

  static const backlogGroups = [
    BacklogGroup(
      title: 'OT面板 冲刺 1',
      issueCount: 1,
      todoCount: 1,
      inProgressCount: 0,
      doneCount: 0,
      items: [
        JiraIssueSummary(
          title: '使用毛球',
          key: 'OT-2',
          status: '待办',
          assigneeInitials: 'MT',
        ),
      ],
    ),
    BacklogGroup(
      title: '待办事项列表',
      issueCount: 1,
      todoCount: 1,
      inProgressCount: 0,
      doneCount: 0,
      items: [
        JiraIssueSummary(
          title: '测试任务1',
          key: 'OT-1',
          status: '待办',
          assigneeInitials: 'MT',
        ),
      ],
    ),
  ];

  static const filters = [
    FilterItem(title: '我的未处理工作项', icon: Icons.account_circle_outlined),
    FilterItem(title: '我报告的', icon: Icons.error_outline_rounded),
    FilterItem(title: '最近查看', icon: Icons.remove_red_eye_outlined),
    FilterItem(title: '所有工作项', icon: Icons.inventory_2_outlined),
    FilterItem(title: '未处理工作项', icon: Icons.sync_problem_outlined),
    FilterItem(title: '最近创建', icon: Icons.add_card_outlined),
    FilterItem(title: '最近解决', icon: Icons.assignment_turned_in_outlined),
    FilterItem(title: '最近更新', icon: Icons.sync_rounded),
    FilterItem(title: '已完成的工作项', icon: Icons.check_circle_outline_rounded),
  ];

  static const assignedIssues = [
    JiraIssueSummary(title: '测试', key: 'OT-1'),
    JiraIssueSummary(title: '使用', key: 'OT-2'),
  ];

  static const dashboardActivities = [
    DashboardActivityItem(
      text: 'maoqiu The 将 OT-2 - 使用毛球 的经办人 改变为 “maoqiu The”',
      issue: 'OT-2',
      time: '2 小时前',
    ),
    DashboardActivityItem(
      text: 'maoqiu The 更新 OT-2 - 使用毛球 的 Sprint',
      issue: 'OT-2',
      time: '2 小时前',
    ),
    DashboardActivityItem(
      text: 'maoqiu The 创建了 OT-2 - 使用毛球',
      issue: 'OT-2',
      time: '2 小时前',
    ),
    DashboardActivityItem(
      text: 'maoqiu The 创建了 OT-1 - 测试任务1',
      issue: 'OT-1',
      time: '3 小时前',
    ),
  ];

  static const notifications = [
    NotificationItem(title: '分配给你的工作项已更新', description: 'OT-2 的经办人发生变化'),
    NotificationItem(
      title: '空间 ottersync 有新的活动',
      description: 'Sprint 和任务状态刚刚同步',
    ),
    NotificationItem(title: '筛选器已保存', description: '我的未处理工作项 已加入最近使用'),
  ];

  static const calendarFilters = ['状态', '经办人', '优先级', '类型'];
}
