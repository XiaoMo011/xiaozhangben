# 小账本 (Xiao Zhangben) — Personal Expense Tracker

## Project Overview

- **App Name**: 小账本
- **Platform**: Android
- **Tech Stack**: Flutter (Dart)
- **Goal**: A simple, fast daily expense tracker for personal use in China
- **Language**: All user-facing text is in Chinese (Simplified)
- **Currency**: RMB (人民币, ¥)
- **User**: Non-technical beginner — the app must be intuitive and require zero training

---

## CRITICAL RULE: Decision-Making Protocol

**The user is a complete beginner in software development. This rule MUST be followed throughout the entire project:**

> For ANY technical decision — no matter how small — you MUST:
> 1. List out the available options (2-4 options)
> 2. Explain each option in plain, non-technical Chinese
> 3. Describe the pros and cons of each option in terms the user can understand
> 4. State your recommendation with reasoning
> 5. WAIT for the user to make a decision before proceeding
>
> NEVER make a technical decision on your own. NEVER assume the user's preference.
> NEVER use jargon without explaining it.

**Examples of technical decisions that require user input:**
- Which local database to use (SQLite / Hive / ObjectBox / etc.)
- UI color scheme and design style
- App architecture patterns (State management choice)
- Which libraries/packages to use for charts, icons, etc.
- How to handle data backup
- App icon design direction
- Any configuration that affects how the app looks or behaves

**What you CAN do without asking:**
- Fix bugs
- Write code once a decision has been made
- Suggest improvements (but wait for approval before implementing)
- Research and provide information

---

## Product Requirements

### Core Features (MVP - Version 1.0)

1. **Record Expense (记一笔)**
   - Input: Amount (RMB, decimal)
   - Select: Category (2-level: major → minor)
   - Set: Date and time (defaults to current time)
   - Optional: Note/memo (max 200 characters)
   - Save to local database

2. **View History (明细)**
   - Chronological list, newest first
   - Each item shows: category icon, category name, amount, date, note preview
   - Tap to edit, swipe to delete
   - Filter by date range and category

3. **Statistics (统计)**
   - Pie chart: spending distribution by major category
   - Bar chart: daily spending trend
   - Time periods: This Month, Last Month, This Year
   - Ranked list of categories by amount

4. **Category Management (类别管理)**
   - Pre-loaded default categories (see below)
   - Add custom major/minor categories
   - Rename existing categories
   - Hide/delete unwanted categories (with confirmation if expenses exist)

5. **Data**
   - All data stored locally on device
   - No internet required
   - No account registration required

### Future Features (v1.1+)

- Search expenses by note text
- Monthly budget with alerts
- Export to CSV/Excel
- Cloud backup
- Receipt photo attachment
- Multiple payment methods (微信, 支付宝, 银行卡, 现金)

### Data Model

```
Expense {
  id: integer (auto-increment, primary key)
  amount: decimal (e.g., 35.50)
  date: datetime (when the expense occurred)
  majorCategory: string (e.g., "餐饮饮食")
  minorCategory: string (e.g., "午餐")
  note: string (optional, max 200 chars)
  createdAt: datetime (auto-set on creation)
  updatedAt: datetime (auto-updated on edit)
}
```

### Screen Flow

**Screen 1: Home (首页)**
- Top section: "今日支出 ¥XX.XX" (today's total, large and prominent)
- Middle: Big green "+" button labeled "记一笔" (Record an expense) — the primary action
- Bottom section: Last 5 expenses in a compact list
- Bottom navigation bar: 首页 | 明细 | 统计 | 设置

**Screen 2: Add Expense (记一笔)**
- Opens when tapping "+" on home screen
- Large numeric keypad (calculator-style) for amount entry
- Category picker: two rows of tappable chips — major categories then sub-categories
- Date/time: defaults to "now", tappable to change
- Note field: text input, placeholder "添加备注..."
- Bottom: "保存" (Save) button
- Design principle: complete recording in under 10 seconds

**Screen 3: History (明细)**
- Scrollable list, newest first
- Each row shows: category icon + name, amount, date, note preview
- Swipe left on a row to delete
- Tap a row to edit
- Top: filter bar (date range, category)
- Shows monthly total at top

**Screen 4: Statistics (统计)**
- Tabs: 本月 | 上月 | 本年
- Pie chart: spending by major category
- Bar chart: daily spending for selected period
- Below chart: ranked list of categories by amount

**Screen 5: Settings (设置)**
- Category management (add/rename/hide)
- Monthly budget setting
- Data export
- About

### UI/UX Principles

1. **Speed first**: Recording an expense should take under 10 seconds
2. **Clarity**: Every screen must be understandable without explanation
3. **Forgiveness**: Undo delete, edit any record, no destructive actions without confirmation
4. **Offline-first**: No feature should require internet access
5. **Chinese-first**: All labels, buttons, messages in Chinese

---

## Expense Categories (2-Level Hierarchy)

### 1. 餐饮饮食 (Food & Dining)
- 早餐 (Breakfast)
- 午餐 (Lunch)
- 晚餐 (Dinner)
- 零食 (Snacks)
- 饮品 (Drinks/Bubble Tea)
- 水果 (Fruits)
- 外卖 (Food Delivery)
- 聚餐 (Group Dining)

### 2. 交通出行 (Transportation)
- 公交 (Bus)
- 地铁 (Subway)
- 打车/网约车 (Taxi/Ride-hailing)
- 加油 (Fuel)
- 停车 (Parking)
- 火车/高铁 (Train/High-speed Rail)
- 飞机 (Flight)
- 共享单车 (Shared Bike)

### 3. 购物消费 (Shopping)
- 日用品 (Daily Necessities)
- 衣物鞋帽 (Clothing & Shoes)
- 数码电子 (Electronics)
- 家居用品 (Home Goods)
- 化妆品/护肤 (Cosmetics/Skincare)
- 书籍 (Books)
- 礼品 (Gifts)

### 4. 居住住房 (Housing)
- 房租 (Rent)
- 水费 (Water Bill)
- 电费 (Electricity Bill)
- 燃气费 (Gas Bill)
- 物业费 (Property Management)
- 网费 (Internet)
- 维修 (Repairs)

### 5. 通讯网络 (Communication)
- 手机话费 (Phone Bill)
- 宽带费 (Broadband)

### 6. 医疗健康 (Health & Medical)
- 看病/挂号 (Doctor Visit)
- 药品 (Medicine)
- 体检 (Health Checkup)
- 牙科 (Dental)
- 保健品 (Supplements)

### 7. 教育学习 (Education)
- 培训课程 (Training Courses)
- 书本文具 (Books & Stationery)
- 考试报名 (Exam Fees)
- 网课会员 (Online Course Subscription)

### 8. 娱乐休闲 (Entertainment)
- 电影 (Movies)
- 演出 (Shows/Concerts)
- 游戏 (Games)
- 旅游 (Travel)
- 运动健身 (Sports/Fitness)
- KTV
- 景点门票 (Attraction Tickets)

### 9. 人情社交 (Social)
- 红包/礼金 (Red Envelope/Gift Money)
- 请客吃饭 (Treating Others)
- 礼物 (Gifts to Others)
- 捐款 (Donations)

### 10. 金融保险 (Finance & Insurance)
- 银行手续费 (Bank Fees)
- 保险 (Insurance)
- 贷款还款 (Loan Repayment)
- 理财亏损 (Investment Loss)

### 11. 宠物育儿 (Pets & Childcare)
- 宠物食品 (Pet Food)
- 宠物医疗 (Pet Medical)
- 宠物用品 (Pet Supplies)
- 奶粉/尿布 (Baby Formula/Diapers)
- 玩具 (Toys)
- 托管/保姆 (Daycare/Nanny)

### 12. 其他杂项 (Miscellaneous)
- 快递费 (Courier/Shipping)
- 办公用品 (Office Supplies)
- 其他 (Other)

---

## Technical Decision Log

This section tracks every technical decision made throughout the project.
Each decision records: date, what was decided, the options presented, and why.

| Date | Decision | Options Considered | Chosen | Rationale |
|------|----------|--------------------|---------|-----------|
| 2026-07-05 | App名称 | 小账本 / 记账 / 随手记 / 我的账本 | 小账本 | 用户选择，亲切好记 |
| 2026-07-05 | 技术栈 | Flutter / Kotlin原生 / React Native / PWA | Flutter | 用户选择，性能好且未来可扩展iPhone |
| 2026-07-05 | 分类体系 | 12大类方案 | 保持不变 | 用户确认满意 |

---

## Development Workflow

### How Claude Code Works on This Project

1. **Starting a new feature**: Claude reads this CLAUDE.md first, then identifies what decisions need user input
2. **Making decisions**: Claude presents options (following the Critical Rule above), user picks one
3. **Implementation**: Claude writes code, creates files, and tests
4. **Review**: Claude explains what was done in plain language
5. **Iteration**: User provides feedback, Claude adjusts

### Commit Conventions

- All git commits should be in Chinese
- Format: `[类型] 简短描述`
- Types: `[功能]` for features, `[修复]` for fixes, `[优化]` for improvements, `[文档]` for docs

### Code Quality Standards

- Code must be well-commented (in Chinese where helpful)
- Variable and function names in English (standard practice)
- No overly clever/short code — readability matters more than brevity
- Test all changes before presenting to user

---

## Current Project Status

### Completed
- [x] App名称确定：小账本
- [x] 技术栈选定：Flutter
- [x] 分类体系确认：12大类
- [x] CLAUDE.md 创建

### In Progress
- [ ] Flutter项目初始化

### Next Steps
1. [x] User reviews and approves this CLAUDE.md ✅
2. [x] User selects tech stack (Flutter) ✅
3. [ ] Initialize Flutter project
4. [ ] Choose local database solution (present options to user)
5. [ ] Choose state management approach (present options to user)
6. [ ] Build the "Add Expense" screen (core flow)
7. [ ] Build the "History" screen
8. [ ] Build the "Statistics" screen
9. [ ] Build the "Settings/Categories" screen
10. [ ] Testing and refinement
11. [ ] Generate APK for installation

---

## Notes for Development

### Android-Specific Considerations
- Target Android API level: to be decided (present options to user)
- App should handle screen rotation gracefully
- App should work offline (no network permission needed for MVP)
- App should respect system dark/light theme

### Data Safety
- All data stays on the user's device
- No analytics, no tracking, no third-party services for MVP
- Backup/export feature must let user control where data goes

### Accessibility
- Font sizes should respect system settings
- Color contrast should be sufficient for readability
- Touch targets should be at least 48dp (Android accessibility guideline)
