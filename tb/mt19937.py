"""

Copyright (c) 2014-2016 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

This is a python implementation of mt19937ar from
http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/emt19937ar.html
http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/CODES/mt19937ar.c

"""

class mt19937(object):
    def __init__(self):
        self.mt = [0]*624
        self.mti = 625

    def seed(self, seed):
        self.mt[0] = seed & 0xffffffff
        for i in range(1,624):
            self.mt[i] = (1812433253 * (self.mt[i-1] ^ (self.mt[i-1] >> 30)) + i) & 0xffffffff
        self.mti = 624

    def init_by_array(self, key):
        self.seed(19650218)
        i = 1
        j = 0
        k = max(624, len(key))
        for ki in range(k):
            self.mt[i] = ((self.mt[i] ^ ((self.mt[i-1] ^ (self.mt[i-1] >> 30)) * 1664525)) + key[j] + j) & 0xffffffff
            i += 1
            j += 1
            if i >= 624:
                self.mt[0] = self.mt[623]
                i = 1
            if j >= len(key):
                j = 0
        for ki in range(624):
            self.mt[i] = ((self.mt[i] ^ ((self.mt[i-1] ^ (self.mt[i-1] >> 30)) * 1566083941)) - i) & 0xffffffff
            i += 1
            if i >= 624:
                self.mt[0] = self.mt[623]
                i = 1
        self.mt[0] = 0x80000000

    def int32(self):
        if self.mti >= 624:
            if self.mti == 625:
                self.seed(5489)

            for k in range(623):
                y = (self.mt[k] & 0x80000000) | (self.mt[k+1] & 0x7fffffff)
                if k < 624 - 397:
                    self.mt[k] = self.mt[k+397] ^ (y >> 1) ^ (0x9908b0df if y & 1 else 0)
                else:
                    self.mt[k] = self.mt[k+397-624] ^ (y >> 1) ^ (0x9908b0df if y & 1 else 0)

            y = (self.mt[623] & 0x80000000) | (self.mt[0] & 0x7fffffff)
            self.mt[623] = self.mt[396] ^ (y >> 1) ^ (0x9908b0df if y & 1 else 0)
            self.mti = 0

        y = self.mt[self.mti]
        self.mti += 1

        y ^= (y >> 11)
        y ^= (y << 7) & 0x9d2c5680
        y ^= (y << 15) & 0xefc60000
        y ^= (y >> 18)

        return y

    def int32b(self):
        if self.mti == 625:
            self.seed(5489)

        k = self.mti

        if k == 624:
            k = 0
            self.mti = 0

        if k == 623:
            y = (self.mt[623] & 0x80000000) | (self.mt[0] & 0x7fffffff)
            self.mt[623] = self.mt[396] ^ (y >> 1) ^ (0x9908b0df if y & 1 else 0)
        else:
            y = (self.mt[k] & 0x80000000) | (self.mt[k+1] & 0x7fffffff)
            if k < 624 - 397:
                self.mt[k] = self.mt[k+397] ^ (y >> 1) ^ (0x9908b0df if y & 1 else 0)
            else:
                self.mt[k] = self.mt[k+397-624] ^ (y >> 1) ^ (0x9908b0df if y & 1 else 0)

        y = self.mt[self.mti]
        self.mti += 1

        y ^= (y >> 11)
        y ^= (y << 7) & 0x9d2c5680
        y ^= (y << 15) & 0xefc60000
        y ^= (y >> 18)

        return y

if __name__ == '__main__':
    mt = mt19937()
    mt.init_by_array([0x123, 0x234, 0x345, 0x456])
    print("1000 outputs of int32")
    s=''
    for i in range(1000):
        s += "%10lu " % mt.int32b()
        if i % 5 == 4:
            print(s)
            s = ''
    if len(s) > 0:
        print(s)
