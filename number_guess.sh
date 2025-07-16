#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

# Check if username exists
USER_DATA=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME';")

if [[ -z $USER_DATA ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user
  INSERT_RESULT=$($PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0);")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME';")
else
  # Existing user
  IFS='|' read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number
SECRET=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=0

echo "Guess the secret number between 1 and 1000:"

while true; do
  read GUESS
  ((GUESS_COUNT++))
  
  # Check if input is integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  if (( GUESS < SECRET ))
  then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET ))
  then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET. Nice job!"
    # Update stats in DB
    # Increase games played
    UPDATE_GAMES=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID;")
    # Check and update best game
    if [[ -z $BEST_GAME ]] || (( GUESS_COUNT < BEST_GAME ))
    then
      UPDATE_BEST=$($PSQL "UPDATE users SET best_game = $GUESS_COUNT WHERE user_id = $USER_ID;")
    fi
    break
  fi
done
