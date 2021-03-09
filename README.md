# Multicasting

Example repo for [post on using UDP Multicast with OTP](https://furlough.merecomplexities.com/elixir/otp/networking/nerves/2021/03/09/fun-with-multicasting.html).

This will broadcast the OS hostname to any multicast listeners on port 49001 on 239.2.3.4. It will also listen on that
post and user the logger to print out those messages from the local node or any peers on the network.

Usage (assuming an Elixir installation)

Setup:

```shell
mix deps.get
```

Running

```shell
iex -S mix
```

There is [Dockerfile](Dockerfile) for running in Docker to illustrate
communicating between nodes - as we can't bind to the same address/port on the same OS.

Usage (if you have [Docker installed](https://docs.docker.com/engine/install/))

```shell
./bin/docker-run.sh
```

or

```shell
docker build -t multicast . && docker run -it multicast iex -S mix
```
