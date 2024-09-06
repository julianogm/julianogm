#!/bin/bash

excluded_authors="Karl Marx"

while true; do
  response=$(curl -s https://favqs.com/api/qotd)
  
  author=$(echo "$response" | jq -r '.quote.author')
  quote=$(echo "$response" | jq -r '.quote.body')

  if [[ ! "$author" =~ $excluded_authors ]]; then
    echo "Citação aceita: \"$quote\" - $author"
    break
  fi
done

marker="<!-- quote_marker -->"
tmp_file=$(mktemp)

awk -v marker="$marker" -v quote="> \"$quote\" - $author" '
BEGIN { found_marker = 0 }
{
  if ($0 == marker) {
    found_marker = 1;
    print;
    print quote;
    next;
  }
  
  if (found_marker && $0 ~ /^> "/) {
    next;
  }

  print;
}
' README.md > "$tmp_file"

mv "$tmp_file" README.md
