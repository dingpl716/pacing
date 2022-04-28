build:
	@mix compile

deps:
	@mix deps.get

clean:
	@rm -rf _build

run:
	@iex -S mix

.PHONY: deps
