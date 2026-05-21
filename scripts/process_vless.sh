
#!/bin/bash
set -euo pipefail

# ==================== 配置 ====================
# 默认输入输出文件名（可通过命令行参数覆盖）
INPUT_FILE="${1:-original.txt}"
OUTPUT_FILE="${2:-BLACK_VLESS_RUS_clean.txt}"

# 国旗映射（与之前相同）
declare -A flags=(
    ["Albania"]="🇦🇱" ["Australia"]="🇦🇺" ["Austria"]="🇦🇹"
    ["Belgium"]="🇧🇪" ["Brazil"]="🇧🇷" ["Bulgaria"]="🇧🇬"
    ["Canada"]="🇨🇦" ["Czechia"]="🇨🇿" ["Czech Republic"]="🇨🇿"
    ["Denmark"]="🇩🇰" ["Egypt"]="🇪🇬" ["Estonia"]="🇪🇪"
    ["Finland"]="🇫🇮" ["France"]="🇫🇷" ["Germany"]="🇩🇪"
    ["Greece"]="🇬🇷" ["Hong Kong"]="🇭🇰" ["Hungary"]="🇭🇺"
    ["Iceland"]="🇮🇸" ["India"]="🇮🇳" ["Indonesia"]="🇮🇩"
    ["Ireland"]="🇮🇪" ["Israel"]="🇮🇱" ["Italy"]="🇮🇹"
    ["Japan"]="🇯🇵" ["Kazakhstan"]="🇰🇿" ["Latvia"]="🇱🇻"
    ["Lithuania"]="🇱🇹" ["Luxembourg"]="🇱🇺" ["Malaysia"]="🇲🇾"
    ["Netherlands"]="🇳🇱" ["The Netherlands"]="🇳🇱" ["New Zealand"]="🇳🇿"
    ["Norway"]="🇳🇴" ["Philippines"]="🇵🇭" ["Poland"]="🇵🇱"
    ["Portugal"]="🇵🇹" ["Romania"]="🇷🇴" ["Saudi Arabia"]="🇸🇦"
    ["Serbia"]="🇷🇸" ["Singapore"]="🇸🇬" ["Slovakia"]="🇸🇰"
    ["Slovenia"]="🇸🇮" ["South Africa"]="🇿🇦" ["South Korea"]="🇰🇷"
    ["Spain"]="🇪🇸" ["Sweden"]="🇸🇪" ["Switzerland"]="🇨🇭"
    ["Taiwan"]="🇹🇼" ["Thailand"]="🇹🇭" ["Turkey"]="🇹🇷"
    ["Ukraine"]="🇺🇦" ["United Arab Emirates"]="🇦🇪" ["United Kingdom"]="🇬🇧"
    ["UK"]="🇬🇧" ["United States"]="🇺🇸" ["USA"]="🇺🇸" ["Vietnam"]="🇻🇳"
)

# 多词国家
declare -A multi_word=(
    ["Hong Kong"]="Hong Kong"
    ["United States"]="United States"
    ["United Kingdom"]="United Kingdom"
    ["Czech Republic"]="Czech Republic"
    ["The Netherlands"]="The Netherlands"
    ["South Korea"]="South Korea"
    ["Saudi Arabia"]="Saudi Arabia"
    ["South Africa"]="South Africa"
    ["New Zealand"]="New Zealand"
    ["United Arab Emirates"]="United Arab Emirates"
)

# ==================== 主逻辑 ====================
echo "开始处理配置文件: $INPUT_FILE -> $OUTPUT_FILE"

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ 错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

# 清空或创建输出文件
> "$OUTPUT_FILE"

# 使用 awk 进行复杂的文本处理
awk -v flags_json="$(for key in "${!flags[@]}"; do echo "\"$key\":\"${flags[$key]}\""; done | paste -sd, | sed 's/^/{/;s/$/}/')" \
-v multi_word_json="$(for key in "${!multi_word[@]}"; do echo "\"$key\":\"${multi_word[$key]}\""; done | paste -sd, | sed 's/^/{/;s/$/}/')" \
'
BEGIN {
    # 将 flags 数组从 JSON 字符串解析到 awk 关联数组
    split(flags_json, flags_entries, ",")
    for (i in flags_entries) {
        gsub(/^[ \t]*"?|"?[ \t]*$/, "", flags_entries[i])
        split(flags_entries[i], kv, ":")
        if (length(kv) == 2) {
            key = kv[1]
            val = kv[2]
            gsub(/^"|"$/, "", key)
            gsub(/^"|"$/, "", val)
            flags[key] = val
        }
    }
    # 将 multi_word 数组从 JSON 字符串解析到 awk 关联数组
    split(multi_word_json, mw_entries, ",")
    for (i in mw_entries) {
        gsub(/^[ \t]*"?|"?[ \t]*$/, "", mw_entries[i])
        split(mw_entries[i], kv, ":")
        if (length(kv) == 2) {
            key = kv[1]
            val = kv[2]
            gsub(/^"|"$/, "", key)
            gsub(/^"|"$/, "", val)
            multi_word[key] = val
        }
    }
}
{
    line = $0
    while (match(line, /vless:\/\/[^[:space:]]+/)) {
        full = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)

        # 提取别名
        alias = "Unknown"
        pos = index(full, "#")
        if (pos > 0) {
            alias = substr(full, pos + 1)
            full = substr(full, 1, pos - 1)
        }

        # ========= 修复乱码名称 =========
        # URL 解码
        gsub(/\+/, " ", alias)
        gsub(/%20/, " ", alias)
        gsub(/%23/, "#", alias)
        gsub(/%2F/, "/", alias)
        gsub(/%2C/, ",", alias)
        gsub(/%3A/, ":", alias)

        # 修复错误的国旗编码（Egern 特有的乱码）
        gsub(/F09F87A9F09F87AA/, "🇩🇪", alias)  # 德国
        gsub(/F09F87A8F09F87AA/, "🇺🇸", alias)  # 美国
        gsub(/F09F87A7F09F87A9/, "🇨🇦", alias)  # 加拿大
        gsub(/F09F87ABF09F87AE/, "🇯🇵", alias)  # 日本
        gsub(/F09F87AFF09F87B5/, "🇷🇺", alias)  # 俄罗斯
        gsub(/F09F87A6F09F87B1/, "🇨🇳", alias)  # 中国
        gsub(/F09F87AEF09F87A9/, "🇸🇬", alias)  # 新加坡
        gsub(/F09F87AFF09F87AA/, "🇫🇷", alias)  # 法国
        gsub(/F09F87ACF09F87A7/, "🇬🇧", alias)  # 英国
        gsub(/F09F87A9F09F87AA/, "🇫🇮", alias)  # 芬兰
        gsub(/F09F87B7F09F87BA/, "🇺🇦", alias)  # 乌克兰

        # 移除残留的十六进制乱码
        gsub(/[A-Z0-9]{8,}/, "", alias)
        
        # 移除多余的数字后缀
        gsub(/[0-9]+[A-Z]+[A-Z0-9]*$/, "", alias)
        
        # 清理多余空格和分隔符
        gsub(/[_,]+/, " ", alias)
        gsub(/[ \t]+/, " ", alias)
        gsub(/^[ \t]+|[ \t]+$/, "", alias)
        # ========= 修复完成 =========

        # 解析国家/城市
        country = ""
        city = ""

        # 优先匹配多词国家
        found = 0
        for (mw in multi_word) {
            if (index(alias, mw) == 1) {
                country = mw
                rest = substr(alias, length(mw) + 1)
                gsub(/^[ \t]+/, "", rest)
                split(rest, parts, " ")
                city = parts[1]
                found = 1
                break
            }
        }

        # 普通两词格式
        if (!found && match(alias, /^[A-Za-z]+ [A-Za-z]/)) {
            split(alias, parts, " ")
            country = parts[1]
            city = parts[2]
        }

        # 只有城市名
        if (!found && country == "" && alias != "Unknown") {
            city = alias
        }

        # 清理城市名
        gsub(/[^A-Za-z\u4e00-\u9fa5-]/, "", city)
        if (city == "" || city == "Unknown") city = "Server"

        # 获取国旗
        flag = "🌍"
        if (country in flags) flag = flags[country]

        # 处理重复
        key = (country == "" ? city : country "|" city)
        count[key]++

        if (count[key] > 1) {
            name = flag " " city " " count[key]
        } else {
            name = flag " " city
        }

        output = full "#" name

        if (!seen[output]++) {
            print output
        }
    }
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

NODE_COUNT=$(grep -c "^vless://" "$OUTPUT_FILE" 2>/dev/null || echo 0)
echo "✅ 处理完成，共 ${NODE_COUNT} 个有效节点"

if [ "$NODE_COUNT" -eq 0 ]; then
    echo "❌ 错误：没有提取到任何有效节点"
    exit 1
fi
