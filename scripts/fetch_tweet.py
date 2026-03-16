# scripts/fetch_latest_supezen.py
import os
import re
import json
import subprocess
import sys
import requests

USER_URL = os.getenv("SUPEZEN_URL", "https://x.com/supezen")

def get_latest_tweet_url(user_url: str) -> str:
    headers = {
        "User-Agent": "Mozilla/5.0"
    }
    resp = requests.get(user_url, headers=headers, timeout=20)
    resp.raise_for_status()
    html = resp.text

    # 简单用正则从 HTML 里找第一个 /supezen/status/xxx
    m = re.search(r'href="(/supezen/status/\d+)"', html)
    if not m:
        raise RuntimeError("找不到最新推文链接，请检查用户是否有公开推文或页面结构变化。")
    path = m.group(1)
    return "https://x.com" + path

def main():
    user_url = USER_URL
    latest_url = get_latest_tweet_url(user_url)
    print(f"Latest tweet URL: {latest_url}", file=sys.stderr)

    # 调用项目自带的 fetch_tweet.py
    result = subprocess.check_output(
        [sys.executable, "scripts/fetch_tweet.py", "--url", latest_url],
        text=True
    )

    data = json.loads(result)
    # 你可以根据需要只保留部分字段
    with open("latest-supezen.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print("saved to latest-supezen.json", file=sys.stderr)

if __name__ == "__main__":
    main()
