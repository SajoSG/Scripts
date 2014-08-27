import sys
import getopt
import urllib2

def main():
	for i in range(10, 32):
		url = "http://www.michaelfranz.com/CS241/testprogs/test0"+str(i)+".txt";
		mp3file = urllib2.urlopen(url);
		output = open('test0'+str(i)+'.txt','wb')
		output.write(mp3file.read())
		output.close()
	print("download done");

if __name__ == "__main__":
    main()
