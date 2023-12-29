def leaf(a,b,c,d,e,f):
    t1 = a + b
    t2 = c + d
    t3 = (a + b) - (c + d)
    t4 = a * d
    t5 = e * f
    t6 = b // 4
    a = t1
    b = t2
    c = t3
    d = t4
    e = t5
    f = t6
    return a,b,c,d,e,f
def toHex(x):
    if x >= 0:
        return x % 2 ** 32
    else:
        return 2**32+x

if __name__ == '__main__':
    # Modify your test pattern here
    a = 7
    b = -10
    c = -4
    d = 8
    e = 98765
    f = 123456

    print(leaf(a,b,c,d,e,f))

    with open('../00_TB/Pattern/I0/mem_D.dat', 'w') as f_data:
        f_data.write('{:0>8x}\n'.format(toHex(a)))
        f_data.write('{:0>8x}\n'.format(toHex(b)))
        f_data.write('{:0>8x}\n'.format(toHex(c)))
        f_data.write('{:0>8x}\n'.format(toHex(d)))
        f_data.write('{:0>8x}\n'.format(toHex(e)))
        f_data.write('{:0>8x}\n'.format(toHex(f)))

    with open('../00_TB/Pattern/I0/golden.dat', 'w') as f_ans:
        f_ans.write('{:0>8x}\n'.format(toHex(a)))
        f_ans.write('{:0>8x}\n'.format(toHex(b)))
        f_ans.write('{:0>8x}\n'.format(toHex(c)))
        f_ans.write('{:0>8x}\n'.format(toHex(d)))
        f_ans.write('{:0>8x}\n'.format(toHex(e)))
        f_ans.write('{:0>8x}\n'.format(toHex(f)))
        f_ans.write('{:0>8x}\n'.format(toHex(leaf(a,b,c,d,e,f)[0])))
        f_ans.write('{:0>8x}\n'.format(toHex(leaf(a,b,c,d,e,f)[1])))
        f_ans.write('{:0>8x}\n'.format(toHex(leaf(a,b,c,d,e,f)[2])))
        f_ans.write('{:0>8x}\n'.format(toHex(leaf(a,b,c,d,e,f)[3])))
        f_ans.write('{:0>8x}\n'.format(toHex(leaf(a,b,c,d,e,f)[4])))
        f_ans.write('{:0>8x}\n'.format(toHex(leaf(a,b,c,d,e,f)[5])))