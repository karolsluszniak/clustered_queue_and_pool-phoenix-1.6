FROM hexpm/elixir:1.12.2-erlang-24.0.5-alpine-3.14.0 as build
RUN apk add --update --no-cache git build-base
RUN mkdir /app
WORKDIR /app
RUN mix do local.hex --force, local.rebar --force
ENV MIX_ENV=prod
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile
COPY assets assets
COPY config config
COPY priv priv
RUN mix assets.deploy
COPY lib lib
COPY rel rel
RUN mix release

FROM alpine:3.14 AS app
RUN apk add --update --no-cache bash openssl postgresql-client libstdc++
ENV MIX_ENV=prod
RUN adduser -D -h /app app
WORKDIR /app
USER app
COPY --from=build --chown=app /app/_build/prod/rel/outer .
CMD env SERVER=1 bin/outer start
