format:
	find . -type f | grep '.glsl$$' | xargs -I{} sh -c 'START=$$(date +%s%3N) && printf "$$1 " && clang-format -i $$1 && END=$$(date +%s%3N) && echo "$$(expr $$END - $$START) ms"' -- {}
	prettier --write .
