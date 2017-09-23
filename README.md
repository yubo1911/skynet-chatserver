# skynet-chatserver
a simple chat server use skynet

git submodule update --init --recursive
cd skynet
make linux
cd ..

# server
skynet/skynet chat/config.lua

# client
python client/client.py
