#!/bin/sh

books=`ls pg*.txt`
#echo $books
no_book_page=`cat no-book.html`
#echo $no_book_page

for book in $books; do
	content=`cat $book`
	if [ -z "$content" ]; then
		echo "$book is empty. Removing!"
		rm "$book"
	else
		if [ "$content" = "$no_book_page" ]; then
			echo "$book got no real book. Removing!"
			rm "$book"
		else
			echo "$book has content."
		fi
	fi
done
