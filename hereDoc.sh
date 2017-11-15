#! /bin/bash

ex yousef.dat <<Eof
:1,$ s/AX|..../AX|2222/
:wq
Eof

ex yousef.dat <<Eof
:1,$ s/VI|..../VI|1111/
:wq
Eof

