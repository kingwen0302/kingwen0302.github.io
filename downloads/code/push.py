# -*- coding: utf-8 -*-
# @Author: LoveNight
# @Date:   2015-11-16 20:45:59
# @Last Modified by:   LoveNight
# @Last Modified time: 2015-11-18 18:07:19
import os
import sys
import json
from bs4 import BeautifulSoup as BS
import requests

"""
hexo 博客专用，向百度站长平台提交所有网址

本脚本必须放在hexo博客的根目录下执行！需要已安装生成百度站点地图的插件。
百度站长平台提交链接：http://zhanzhang.baidu.com/linksubmit/index
主动推送：最为快速的提交方式，推荐您将站点当天新产出链接立即通过此方式推送给百度，以保证新链接可以及时被百度收录。
从中找到自己的接口调用地址
"""

## url = 去上面的链接找自己的推送接口
url = "http://data.zz.baidu.com/urls?site=www.aaaa.com&token=aaaa"
baidu_sitemap = os.path.join(sys.path[0], 'public', 'baidusitemap.xml')
google_sitemap = os.path.join(sys.path[0], 'public', 'sitemap.xml')
sitemap = [baidu_sitemap, google_sitemap]

assert (os.path.exists(baidu_sitemap) or os.path.exists(
    google_sitemap)), "没找到任何网站地图，请检查！"


# 从站点地图中读取网址列表
def getUrls():
    urls = []
    for _ in sitemap:
        if os.path.exists(_):
            # with open(_, "r", encoding="utf-8") as f:
            with open(_, "r") as f:
                xml = f.read()
            soup = BS(xml, "xml")
            tags = soup.find_all("loc")
            urls += [x.string for x in tags]
            if _ == baidu_sitemap:
                tags = soup.find_all("breadCrumb", url=True)
                urls += [x["url"] for x in tags]
    return urls


# POST提交网址列表
def postUrls(urls):
    urls = set(urls)  # 先去重
    print("一共提取出 %s 个网址" % len(urls))
    data = "\n".join(urls)
    for u in urls:
        print u
    return requests.post(url, data=data).text


if __name__ == '__main__':

    urls = getUrls()
    result = postUrls(urls)
    print("提交结果：")
    print(result)
    ## msvcrt.getch()
