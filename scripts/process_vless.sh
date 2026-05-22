#!/bin/bash
set -euo pipefail

# ==================== 配置 ====================
INPUT_FILE="${1:-original.txt}"
OUTPUT_FILE="${2:-BLACK_VLESS_RUS_clean.txt}"

# ==================== 主逻辑 ====================
echo "开始处理配置文件: $INPUT_FILE -> $OUTPUT_FILE"

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ 错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

> "$OUTPUT_FILE"

awk '
{
    line = $0
    while (match(line, /vless:\/\/[^[:space:]]+/)) {
        full = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)

        # 提取 URL 部分（不含别名）
        url = full
        alias = ""
        pos = index(full, "#")
        if (pos > 0) {
            alias = substr(full, pos + 1)
            url = substr(full, 1, pos - 1)
        }

        # 去重：同一个 URL 只保留一个
        if (seen[url]++) continue

        count++
        output = url "#🇷🇺 公益 " count
        print output
    }
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

NODE_COUNT=$(grep -c "^vless://" "$OUTPUT_FILE" 2>/dev/null || echo 0)
echo "✅ 处理完成，共 ${NODE_COUNT} 个有效节点"

if [ "$NODE_COUNT" -eq 0 ]; then
    echo "❌ 错误：没有提取到任何有效节点"
    exit 1
fi
