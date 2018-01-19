# coding=utf-8

# list
classmates = ['Michael', 'Bob', 'Tracy']

# tulp
mates = ('lk', 'lkf', 'datalearning')

# dict
dict = {'lk': 24, 'dy': 18}

# set
s = set([1, 2, 2, 3])
print(s)

print(dict['dy'])

for mate in classmates:
    print(mate)

# if else
age = int(input('age: '))  # 类型强转
if age >= 18:
    print('your age is: ', age)
    print('adult')
elif age >= 6:
    print('teenager')
else:
    print('kid')

sum = 0
for x in range(101):
    sum = sum + x
print(sum)


# return None 可以简写为 return
def py_abs(x):
    if x >= 0:
        return x
    else:
        return -x


def none_return():
    pass

# 函数是顺序执行，遇到 return 语句或者最后一行函数语句就返回
def fib(max):
    n, a, b = 0, 0, 1
    while n < max:
        # print(b)
        a, b = b, a + b
        n = n + 1

    return 'done'

print(fib(6))

# generator的函数，在每次调用 next() 的时候执行，遇到 yield 语句返回，再次执行时从上次返回的 yield 语句处继续执行
def fib1(max):
    n, a, b = 0, 0, 1
    while n < max:
        yield b
        a, b = b, a + b
        n = n + 1

    return 'done'
