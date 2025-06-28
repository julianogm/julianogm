#!/bin/bash

echo "=== DEBUG: Starting script ==="

# Debug: Verificar se as variáveis de ambiente estão definidas
echo "DEBUG: AUTHORS_LIST = '$AUTHORS_LIST'"
echo "DEBUG: FAVQS_TOKEN defined = $([ -n "$FAVQS_TOKEN" ] && echo "YES" || echo "NO")"

IFS=',' read -ra temp_authors <<< "$AUTHORS_LIST"
echo "DEBUG: temp_authors array length = ${#temp_authors[@]}"
echo "DEBUG: temp_authors content = ${temp_authors[*]}"

authors=()
for author in "${temp_authors[@]}"; do
  authors+=("${author//_/+}")
done

echo "DEBUG: authors array length = ${#authors[@]}"
echo "DEBUG: authors content = ${authors[*]}"

selected_author=${authors[$RANDOM % ${#authors[@]}]}
echo "DEBUG: Selected author = '$selected_author'"

echo "DEBUG: Making API request to https://favqs.com/api/quotes/?filter=$selected_author&type=author"
response=$(curl -s -H "Authorization: Token token=\"$FAVQS_TOKEN\"" "https://favqs.com/api/quotes/?filter=$selected_author&type=author")

echo "DEBUG: API response length = ${#response}"
echo "DEBUG: API response preview = ${response:0:200}..."

quote_count=$(echo "$response" | grep -o '"body"' | wc -l)
echo "DEBUG: Quote count found = $quote_count"

if [ "$quote_count" -gt 0 ]; then
  echo "DEBUG: Using author-specific quote"
  random_index=$((RANDOM % quote_count + 1))
  echo "DEBUG: Random index selected = $random_index"
  
  author=$(echo "$response" | grep -o '"author":"[^"]*"' | sed -n "${random_index}p" | sed 's/"author":"\([^"]*\)"/\1/')
  quote=$(echo "$response" | grep -o '"body":"[^"]*"' | sed -n "${random_index}p" | sed 's/"body":"\([^"]*\)"/\1/')
  
  echo "DEBUG: Extracted author = '$author'"
  echo "DEBUG: Extracted quote = '$quote'"
else
  echo "DEBUG: No quotes found for author, using quote of the day"
  response=$(curl -s https://favqs.com/api/qotd)
  echo "DEBUG: QOTD API response = ${response:0:200}..."
  
  author=$(echo "$response" | grep -o '"author":"[^"]*"' | sed 's/"author":"\([^"]*\)"/\1/')
  quote=$(echo "$response" | grep -o '"body":"[^"]*"' | sed 's/"body":"\([^"]*\)"/\1/')
  
  echo "DEBUG: QOTD author = '$author'"
  echo "DEBUG: QOTD quote = '$quote'"
fi

current_date=$(date +"%A, %B %d, %Y")
echo "DEBUG: Current date = '$current_date'"

marker="<!-- quote_marker -->"
tmp_file=$(mktemp)
echo "DEBUG: Temp file = '$tmp_file'"

date="#### $current_date. Quote of the day:\n"

echo "DEBUG: Updating README.md..."
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
echo "DEBUG: README.md updated successfully"
echo "=== DEBUG: Script completed ==="