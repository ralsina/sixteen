build: $(wildcard src/**/*.cr) $(wildcard base16/*) shard.yml
	shards build -Dstrict_multi_assign -Dno_number_autocast
release: $(wildcard src/**/*.cr) $(wildcard base16/*) shard.yml
	shards build --release
static: $(wildcard src/**/*.cr) $(wildcard base16/*) shard.yml
	shards build --release --static
	strip bin/sixteen
