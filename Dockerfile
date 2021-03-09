FROM elixir:1.11.3-alpine

RUN apk add \
	gcc \
	g++ \
	git \
	make \
	musl-dev

RUN mix do local.hex --force, local.rebar --force

WORKDIR /multicasting

COPY . .

RUN mix deps.get

RUN mix compile




