while true; do
  sleep 1
  elm make src/Main.elm
  perl -pi -e 's/<head>/<head><link type="text\/css" rel="stylesheet" href="styles.css">/' index.html
done
