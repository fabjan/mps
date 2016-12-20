HOST=127.0.0.1
PORT=80

test "$1" && PORT=$1
test "$2" && HOST=$2

function maybe {
  echo $(($RANDOM % 2 * $1))
}

echo "spamming commands to $HOST:$PORT"

while true
do
  DPAD=$(( `maybe 1` + `maybe 2` +  `maybe 4` + `maybe 8`))
  BUTTONS=$(( `maybe 16` + `maybe 32` + `maybe 64` + `maybe 128` ))
  INPUT=$(( $DPAD + $BUTTONS ))
  echo "$INPUT"
  sleep 0.1
done | nc $HOST $PORT
