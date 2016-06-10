#!/bin/sh


books=`ls pg*.txt`
books_file='books.txt'
echo "Merging the following books into '$books_file':"
echo "$books"

# Substring that marks the end of the book.
book_end="*** END OF THIS PROJECT GUTENBERG EBOOK"

# Remove the file containing the books, if it exists.
if [ -e "$books_file" ]; then
	mv "$books_file" "$books_file.bkp"
fi

# Merge books to a single file.
for book in $books; do
	# Write book, until we find the string that marks the end of it.
	cat "$book" | while read LINE; do
		echo "$LINE" >> "$books_file"
		case "$LINE" in
			$book_end*) break ;;
		esac
	done
	echo "" >> "$books_file"
	echo "" >> "$books_file"
	echo "" >> "$books_file"
done
