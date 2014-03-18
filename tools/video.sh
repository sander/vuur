if [ "$1" == "1" ]; then
  ip="131.155.174.170"
else
  ip="131.155.175.250"
fi

timestamp=$(node -e 'console.log(new Date().getTime())')
name="../data/video-$timestamp-$1.asf"

/Applications/VLC.app/Contents/MacOS/VLC -I dummy --run-time=3600 http://$ip:80/videostream.cgi?user=guest\&pwd=breakout --sout=file/asf:$name vlc://quit
