while true; do
  sleep 1
  elm make src/Main.elm
  perl -pi -e 's/<head>/<head><link href="https:\/\/fonts.googleapis.com\/css\?family=Roboto" rel="stylesheet"><link type="text\/css" rel="stylesheet" href="styles.css">/' index.html
done
