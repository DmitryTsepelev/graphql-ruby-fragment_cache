default: test

test:
	bundle exec rake
	CI=true bundle exec rake

lint:
	bundle exec rubocop

release: test lint
	gem release -t
	git push
	git push --tags
