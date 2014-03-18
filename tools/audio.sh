timestamp=$(node -e 'console.log(new Date().getTime())')
name="../data/audio-$timestamp-$1.wav"

sox -d $name
