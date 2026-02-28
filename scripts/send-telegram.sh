#!/bin/bash

MESSAGE=$1
CHAT_ID=${TELEGRAM_CHAT_ID}
BOT_TOKEN=${TELEGRAM_BOT_TOKEN}

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"Message content\""
    exit 1
fi

if [ -z "$CHAT_ID" ]; then
    echo "Error: TELEGRAM_CHAT_ID environment variable is not set."
    exit 1
fi

if [ -z "$BOT_TOKEN" ]; then
    echo "Error: TELEGRAM_BOT_TOKEN environment variable is not set."
    exit 1
fi

PAYLOAD=$(jq -n --arg chat_id "$CHAT_ID" --arg text "$MESSAGE" --arg parse_mode "HTML" "{chat_id: $chat_id, text: $text, parse_mode: $parse_mode}")

RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

if echo "$RESPONSE" | jq -e ".ok" > /dev/null; then
    echo "Successfully sent Telegram notification."
else
    echo "Failed to send Telegram notification: $RESPONSE"
    exit 1
fi
