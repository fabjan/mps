HOST=127.0.0.1
PORT=52259

test "$1" && HOST=$1
test "$2" && PORT=$2 

function maybe {
  echo $(($RANDOM % 2 * $1))
}

echo "spamming commands to $HOST:$PORT"

while true
do
  DPAD=$(( `maybe 1` + `maybe 2` +  `maybe 4` + `maybe 8`))
  INPUT="$DPAD"
  echo "$INPUT"
  sleep 0.1
done | nc $HOST $PORT
