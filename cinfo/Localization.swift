//
//  Localization.swift
//  cinfo
//
//  A lightweight string table for English / Mandarin UI chrome.
//  University names, descriptions, and ranking labels remain in English
//  as they are internationally recognised proper terms.
//
//  Usage:  l("key", lang)   where lang is "en" or "zh"
//

import Foundation

// swiftlint:disable line_length
private let strings: [String: [String: String]] = [

    // Tabs
    "tab_home":         ["en": "Home",              "zh": "首页"],
    "tab_backpack":     ["en": "Backpack",          "zh": "背包"],
    "tab_rankings":     ["en": "Discover",           "zh": "探索"],
    "tab_rankings_sub": ["en": "Explore schools, rankings, and key details",
                         "zh": "探索院校、排名与关键信息"],
    "tab_settings":     ["en": "Settings",          "zh": "设置"],

    // Backpack tab — folders
    "backpack_title": ["en": "My Backpack", "zh": "我的背包"],
    "backpack_info_a11y": ["en": "About Backpack", "zh": "关于背包"],
    "backpack_intro": [
        "en": "Your backpack keeps all your materials in one place, and helps you track application progress easily ⏳. Backpack is seamlessly connected with AI; its guidance is automatically reflected here, and the materials continuously power smarter, more personalized recommendations tailored to you 🎯.",
        "zh": "把所有资料集中在一处。背包与 AI 无缝衔接：AI 的建议会自动体现在这里，资料也会持续驱动更智能、更贴合你的个性化推荐。"
    ],
    "backpack_files_folder": ["en": "Files",       "zh": "文件"],
    "backpack_my_schools":   ["en": "My Schools",  "zh": "我的院校"],
    "backpack_interests_folder": ["en": "Interests", "zh": "兴趣"],
    "backpack_interests_empty_title": ["en": "No interests yet", "zh": "暂无兴趣内容"],
    "backpack_interests_empty_detail": [
        "en": "Keep track of subjects, fields, and activities you want to explore.",
        "zh": "记录你想探索的学科、领域与活动。"
    ],
    "backpack_my_schools_empty_title": ["en": "No saved schools", "zh": "暂无收藏院校"],
    "backpack_my_schools_empty_detail": ["en": "Tap the heart on any university card in Discover to save it here.",
                                          "zh": "在「探索」中点击任意院校卡片上的心形图标，即可收藏到此。"],
    "backpack_my_schools_remove": ["en": "Remove", "zh": "移除"],
    "cancel":           ["en": "Cancel",           "zh": "取消"],
    "picker_school_status_a11y":     ["en": "Application status", "zh": "申请状态"],
    "picker_school_likelihood_a11y": ["en": "Likelihood", "zh": "院校档位"],
    "picker_tap_to_choose_a11y": ["en": "Shows a list of choices.", "zh": "显示可选列表。"],
    "likelihood_dream": ["en": "Dream", "zh": "冲刺"],
    "likelihood_target": ["en": "Target", "zh": "目标"],
    "likelihood_safety": ["en": "Safety", "zh": "保底"],
    "likelihood_financial_safety": ["en": "Financial Safety", "zh": "经济保底"],
    "status_in_progress": ["en": "In progress", "zh": "进行中"],
    "status_applied": ["en": "Applied", "zh": "已提交"],
    "status_accepted": ["en": "Accepted", "zh": "已录取"],
    "status_waitlisted": ["en": "Waitlisted", "zh": "候补"],
    "status_rejected": ["en": "Rejected", "zh": "未录取"],
    "status_attending": ["en": "Attending", "zh": "就读"],
    "heart_save_a11y":  ["en": "Save to My Schools", "zh": "保存到我的院校"],
    "heart_remove_a11y":["en": "Remove from My Schools", "zh": "从我的院校移除"],
    "ai_rec_badge":     ["en": "AI Rec", "zh": "AI 推荐"],
    "my_choice_badge":  ["en": "My Choice", "zh": "自选"],

    // Navigation titles
    "app_title":        ["en": "Universities",      "zh": "大学信息"],

    // Feature card titles & subtitles
    "tab_match":        ["en": "Match",             "zh": "匹配"],
    "tab_match_sub":    ["en": "Find your best-fit schools",
                         "zh": "发现最适合你的大学"],
    "tab_apply":        ["en": "Apply",             "zh": "申请"],
    "tab_apply_sub":    ["en": "Plan and manage your applications",
                         "zh": "规划并管理你的申请"],
    "tab_budget":       ["en": "Budget",            "zh": "预算"],
    "tab_budget_sub":   ["en": "Estimate costs and plan your budget",
                         "zh": "估算费用，规划你的预算"],

    // Home screen
    "top_10":           ["en": "Top 10 Institutions", "zh": "综合前十"],
    "top_10_srs_intro": ["en": "We're excited to introduce our new ranking model - SRS. It's the first model to put students at the center. It ranks how well universities are equipped to help you grow, thrive, and succeed 🎓🚀. Tap to learn more.",
                         "zh": "我们很高兴推出全新的排名模型——SRS。这是首个以学生为中心的模型，衡量大学如何帮助你成长、茁壮并成功。前往「探索」了解更多。"],
    "countries_covered":["en": "Countries Covered", "zh": "涵盖地区"],
    "stat_unis":        ["en": "Universities",      "zh": "大学"],
    "stat_countries":   ["en": "Countries",         "zh": "国家/地区"],
    "stat_rankings":    ["en": "Rankings\nTracked", "zh": "排名\n系统"],
    "avg_label":        ["en": "avg",               "zh": "均值"],

    // Rankings screen
    "search_prompt":    ["en": "Search universities", "zh": "搜索大学"],
    "discover_intro":   ["en": "🎓 Explore universities and find the key information you need before starting your academic journey. Compare leading global rankings side by side: QS, Times Higher Education, U.S. News, and Shanghai ARWU, with intuitive graphs that show how each school performs over time. You can also explore our proprietary SRS ranking to understand how well a university is equipped to support your success. \n\nWe're always adding more institutions worldwide 🌍. Don't see yours yet? Tap the sparkles button ✨ for your AI assistant and ask him anything.",
                         "zh": "🎓 探索全球院校，收集启程求学所需的关键信息。并排对比 QS、泰晤士高等教育（THE）、U.S. News 与上海软科（ARWU）等权威排名，并通过直观图表查看各校历年走势。你还可以了解我们自主研发的 SRS 排名，评估大学在支持你取得成功方面的实力。我们会持续收录世界各地的更多院校 🌍。还没看到你的学校？点击顶部 ✨ 打开 AI，尽情提问。"],
    "discover_info_a11y":["en": "About Discover", "zh": "关于探索"],
    "discover_ai_a11y": ["en": "AI assistant", "zh": "AI 助手"],
    "explore_school_fmt": ["en": "Explore %@", "zh": "探索 %@"],
    "ownership_public":  ["en": "Public",    "zh": "公立"],
    "ownership_private": ["en": "Private",   "zh": "私立"],
    "per_year_usd":     ["en": "/ year (USD)",      "zh": "/ 年（美元）"],
    "per_year_cny":     ["en": "year (CNY)",        "zh": "年（人民币）"],

    // Home currency setting
    "home_currency":    ["en": "Home Currency",     "zh": "本地货币"],
    "home_currency_hint":["en": "Tap any tuition fee to convert to your home currency.",
                          "zh": "点击学费金额可换算为本地货币。"],

    // Filter tabs
    "filter_all":       ["en": "All",               "zh": "全部"],
    "filter_europe":    ["en": "🇪🇺 Europe",         "zh": "🇪🇺 欧洲"],
    "filter_other":     ["en": "🌏 Other",           "zh": "🌏 其他"],
    "filter_australia": ["en": "🇦🇺 Australia",      "zh": "🇦🇺 澳洲"],
    "filter_canada":    ["en": "🇨🇦 Canada",         "zh": "🇨🇦 加拿大"],
    "filter_singapore": ["en": "🇸🇬 Singapore",      "zh": "🇸🇬 新加坡"],
    "filter_china":     ["en": "🇨🇳 China",          "zh": "🇨🇳 中国"],

    // Reorder sheet
    "customize_tabs":   ["en": "Customize Tabs",    "zh": "自定义标签"],
    "reorder_hint":     ["en": "Drag to reorder. \"All\" is always first.",
                         "zh": "拖拽排序。「全部」始终排在最前。"],
    "done":             ["en": "Done",              "zh": "完成"],

    // Settings
    "appearance":       ["en": "Appearance",        "zh": "外观"],
    "light":            ["en": "Light",             "zh": "浅色"],
    "dark":             ["en": "Dark",              "zh": "深色"],
    "auto":             ["en": "Auto",              "zh": "跟随系统"],
    "language":         ["en": "Language",          "zh": "语言"],
    "lang_en":          ["en": "English",           "zh": "English"],
    "lang_zh":          ["en": "Mandarin",          "zh": "中文"],
    "appearance_hint":  ["en": "Auto follows your device setting.",
                         "zh": "自动模式跟随手机系统设置。"],
    "settings_match_section": ["en": "Match", "zh": "匹配"],
    "settings_auto_add_ai_schools": ["en": "Add AI recommendations to My Schools",
                                      "zh": "将 AI 推荐自动加入我的院校"],
    "settings_auto_add_ai_schools_footer": [
        "en": "When Match suggests universities in a reply, they are added to My Schools automatically. Turn off to keep recommendations in chat only.",
        "zh": "在「匹配」中 AI 回复里提到的院校会自动加入「我的院校」。关闭后仅在对话中展示推荐；你仍可在「探索」中用心形手动收藏。"
    ],
]
// swiftlint:enable line_length

/// Look up a localised string. Falls back to English, then the raw key.
func l(_ key: String, _ lang: String) -> String {
    strings[key]?[lang] ?? strings[key]?["en"] ?? key
}
