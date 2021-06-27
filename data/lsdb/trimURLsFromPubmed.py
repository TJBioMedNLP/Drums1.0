import re, sys, os, urllib2
import socket

timeout = 10
socket.setdefaulttimeout(timeout)


purl = re.compile('((https?|ftp|gopher|telnet|file|notes|ms-help):((//)|(\\\\))+[\w\d:#@%/;$()~_?\+-=\\\.&]*)')


def getSrc4Url(url):
    pEnd = re.compile('\\s?[^a-zA-Z0-9_]+$')
    print url
    rlt = pEnd.search(url)
    if rlt:
        url = url[:rlt.start()]
    try:
        headers = {'User-Agent':'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6'}
        req = urllib2.Request(url = page_url,headers = headers)
        src = urllib2.urlopen(req).read()
    except:
        src = ''
    return src

def urlNormalize(url):
    urls = []
    src = getSrc4Url(url)
    
    if not src:
        ms = purl.finditer(url) 
        if ms:
            for m in ms:
                url = m.group(0)
                src = getSrc4Url(url)
                if src:
                    URL={}
                    URL['url'] = url
                    URL['src'] = src
                    urls.append(URL)
    else:
        URL={}
        URL['url'] = url
        URL['src'] = src
        urls.append(URL)
    return urls

lines = open('url-pubmed.txt', 'r').readlines()
count = 0
fmap = open('urlIndexMap', 'a')
flog = open('url.log', 'a')
for line in lines:
    print '<<<' + line + '>>>'
    line = line.lstrip()
    line = line.rstrip()
    
    
    page_url = line
    urls = urlNormalize(page_url)
    
    if urls:
        subIndex = 0
        for url in urls:
            targetFile = './test/' + str(count) + '-' + str(subIndex)
            fsrc = open(targetFile, 'w')
            fsrc.write(url['src'])
            fsrc.close()
            
            print '>>>' + page_url        
            fmap.write(str(count) + '-' + str(subIndex))
            fmap.write('\t' + url['url'])
            fmap.write('\n')
            subIndex += 1
    else:
        msg = 'ERROR:\t' + page_url
        print '---' + msg
        flog.write(msg + '\n')
        
        
    count+=1
flog.close()
fmap.close()

os.system('text2classify --input test --output lsdb.rlt  --classifier lsdb.classifier')

