#!/bin/bash

excluded_authors="Karl Marx"

while true; do
  response=$(curl -s https://favqs.com/api/qotd)
  
  author=$(echo "$response" | jq -r '.quote.author')
  quote=$(echo "$response" | jq -r '.quote.body')

  if [[ ! "$author" =~ $excluded_authors ]]; then
    echo "Quote accepted: \"$quote\" - $author"
    break
  fi
done

current_date=$(date +"%A, %B %d, %Y")

marker="<!-- quote_marker -->"
tmp_file=$(mktemp)

date="$current_date. Quote of the day:\n"

awk -v marker="$marker" -v date_msg="$date" -v quote="> \"$quote\" - $author" '
BEGIN { found_marker = 0 }
{
  print;
  if ($0 == marker) {
    print date_msg;
    print quote;
    exit;
  }
}
' README.md > "$tmp_file"

mv "$tmp_file" README.md
