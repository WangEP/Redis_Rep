# IWQoS-22-HPUCache
The Code for **HPUCache: Toward High Performance and Resource
Utilization in Clustered Cache via Data Copying and
Instance Merging**

## Directory Structure

```
.
├── client -> A Redis Client forked from vipshop/hiredis-vip. 
├── server -> A Redis server modification from offical version 6.22
└── tools  -> some tools used in experiment.
```

## Compile 

We use make to build our system. 

### Client

``` bash
cd ./client
make -j
```

### Server

```sh
cd ./server
./build.sh
```

## Run

We build the Redis cluster and run experiment via bash script in
 ```./utils/utils```
