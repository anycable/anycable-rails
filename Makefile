all: release

release:
	gem release anycable-rails-core
	gem release anycable-rails -t
	git push
	git push --tags
