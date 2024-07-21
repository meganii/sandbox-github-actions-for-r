import re
import requests
import pandas as pd
import cairosvg

import urllib

from PIL import Image


def getSbText():
    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
    header = {
        'User-Agent': user_agent
    }
    url = "https://scrapbox.io/api/pages/villagepump/アクティブユーザーの移り変わり。/text"
    return requests.get(url, headers=header).text


def getUsersFromSbText(text):
    users = re.findall('\[([^\]]*?)\.icon\]', text)
    return users


def getTimelineDataFrameFromSbText(text):
    # Data frame
    dfName = []
    dfStart = []

    result = re.finditer(r'^\[?(\d{4}/\d{2})\]?(.*)$', text, re.MULTILINE)
    for m in result:
        if not m:
            continue
        if m[2] == '':
            continue

        d = m[1].split('/')
        year = int(d[0])
        month = int(d[1])

        users = getUsersFromSbText(m[2])
        for username in users:
            dfName.append(username)
            dfStart.append(f"{year}-{month}-01")

    return pd.DataFrame({'Name': dfName, 'Date': dfStart}, columns=['Name', 'Date'])

def prepareImages(icons):
    for icon in icons:
        try:
            url = "https://scrapbox.io/api/pages/villagepump/" + \
                    urllib.parse.quote(icon) + "/icon"    
            print(url)
            downloadFile(url, "./icons/" + icon + ".png")
        except:
            print(icon, "error")

def downloadFile(url, dst_path):
    try:
        header = {
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36"
        }
        res = requests.get(url, headers=header)
        if res.status_code == 200:
            fetchAndSaveImage(url, header, dst_path)
        else:
            # who icon
            fetchAndSaveImage("https://scrapbox.io/api/pages/villagepump/who/icon", header, dst_path)

    except requests.exceptions.RequestException as e:
        print(e)

def fetchAndSaveImage(url, header, dst_path):
    with requests.get(url, headers=header, stream=True) as res:
        type = res.headers["content-type"]

        if type.startswith("image/svg+xml"):
            cairosvg.svg2png(url=url, write_to=dst_path)
        else:
            with open(dst_path, "wb") as f:
                [f.write(chunk)
                for chunk in res.iter_content(chunk_size=1024) if chunk]

            if type == "image/jpeg" or type == "image/gif":
                im = Image.open(dst_path).convert('RGB')
                im.save(dst_path)


def main():
    # Create data for Ganttchart
    sbText = getSbText()
    df = getTimelineDataFrameFromSbText(sbText)
    df.to_csv("./data.csv", index=False)

    # Prepare icon png
    prepareImages(df["Name"].unique())


if __name__ == "__main__":
    main()
