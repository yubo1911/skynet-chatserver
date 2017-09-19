# -*- coding: utf-8 -*-
from __future__ import print_function
import socket
import select
import struct
import os
import sys
import threading

HOST = "127.0.0.1"
PORT = 7000

buff = []


def thread_epoll():
    epoll = select.epoll()
    epoll.register(s.fileno(), select.EPOLLIN)
    handlers[s.fileno()] = handle_socketdata
    while True:
        events = epoll.poll(1000)
        for fileno, event in events:
            if not (event & select.EPOLLIN):
                continue
            handle_func = handlers.get(fileno, None)
            if not handle_func:
                continue
            handle_func()


def handle_socketdata():
    data = s.recv(1024)
    if data:
        buff.extend(data)
    print(buff)
    print('>>>', end='')
    sys.stdout.flush()

handlers = {}
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))

threading.Thread(target=thread_epoll, args=()).start()

while True:
    data = raw_input('>>>')
    if data == 'quit':
        os._exit(0)
    data = struct.pack(">H{}s".format(len(data)), len(data), data)
    s.sendall(data)
