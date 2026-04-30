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
    "tab_rankings":     ["en": "Discover",           "zh": "探索"],
    "tab_rankings_sub": ["en": "Explore schools, rankings, and key details",
                         "zh": "探索院校、排名与关键信息"],
    "tab_files":        ["en": "Files",             "zh": "文件"],
    "tab_settings":     ["en": "Settings",          "zh": "设置"],

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
    "countries_covered":["en": "Countries Covered", "zh": "涵盖地区"],
    "stat_unis":        ["en": "Universities",      "zh": "大学"],
    "stat_countries":   ["en": "Countries",         "zh": "国家/地区"],
    "stat_rankings":    ["en": "Rankings\nTracked", "zh": "排名\n系统"],
    "avg_label":        ["en": "avg",               "zh": "均值"],

    // Rankings screen
    "search_prompt":    ["en": "Search universities", "zh": "搜索大学"],
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
]
// swiftlint:enable line_length

/// Look up a localised string. Falls back to English, then the raw key.
func l(_ key: String, _ lang: String) -> String {
    strings[key]?[lang] ?? strings[key]?["en"] ?? key
}
