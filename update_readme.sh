#!/bin/bash

echo "DEBUG: AUTHORS_LIST='$AUTHORS_LIST'"
echo "DEBUG: FAVQS_TOKEN='${FAVQS_TOKEN:0:4}...'" # só mostra início do token

IFS=',' read -ra temp_authors <<< "$AUTHORS_LIST"

authors=()
for author in "${temp_authors[@]}"; do
  authors+=("${author//_/+}")
done

selected_author=${authors[$RANDOM % ${#authors[@]}]}

response=$(curl -s -H "Authorization: Token token=\"$FAVQS_TOKEN\"" "https://favqs.com/api/quotes/?filter=$selected_author&type=author")

quote_count=$(echo "$response" | grep -o '"body"' | wc -l)

if [ "$quote_count" -gt 0 ]; then
  random_index=$((RANDOM % quote_count + 1))
  
  author=$(echo "$response" | grep -o '"author":"[^"]*"' | sed -n "${random_index}p" | sed 's/"author":"\([^"]*\)"/\1/')
  quote=$(echo "$response" | grep -o '"body":"[^"]*"' | sed -n "${random_index}p" | sed 's/"body":"\([^"]*\)"/\1/')
  
  echo "DEBUG: Extracted author = '$author'"
  echo "DEBUG: Extracted quote = '$quote'"
else
  response=$(curl -s https://favqs.com/api/qotd)
  
  author=$(echo "$response" | grep -o '"author":"[^"]*"' | sed 's/"author":"\([^"]*\)"/\1/')
  quote=$(echo "$response" | grep -o '"body":"[^"]*"' | sed 's/"body":"\([^"]*\)"/\1/')
  
  echo "DEBUG: QOTD author = '$author'"
  echo "DEBUG: QOTD quote = '$quote'"
fi

current_date=$(date +"%A, %B %d, %Y")

marker="<!-- quote_marker -->"
tmp_file=$(mktemp)

date="#### $current_date. Quote of the day:\n"

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