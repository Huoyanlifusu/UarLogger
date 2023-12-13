import turtle as t
import random

def initBoard():
    t.pensize(1)
    t.speed(0)

    for i in range(11):
        #画笔定位定方向
        t.up()
        t.goto(0,i*20)
        t.seth(0)
        t.down()

        #开始绘制横线
        t.forward(200)

    for j in range(11):
        t.up()
        t.goto(j*20,0)
        t.seth(90)
        t.down()

        t.forward(200)

def initChess():
    beginChess = [[0 for i in range(18)] for j in range(18)]
    return beginChess

def blackChess(x, y):
    t.fillcolor('black')
    t.up()
    t.goto(x*20+5, y*20)
    t.down()

    #drawBlackChess
    t.begin_fill()
    t.circle(5)
    t.end_fill()

def whiteChess(x,y):
    t.fillcolor('white')
    t.up()
    t.goto(x*20+5,y*20)
    t.down()

    t.begin_fill()
    t.circle(5)
    t.end_fill()

def Win(chess):
    for i in range(6):
        for j in range(6):
            if chess[i][j] == chess[i+1][j] == chess[i+2][j] == chess[i+3][j] == chess[i+4][j] == 1:
                return True
            if chess[i][j] == chess[i][j+1] == chess[i][j+2] == chess[i][j+3] == chess[i][j+4] == 1:
                return True
            if chess[i][j] == chess[i+1][j+1] == chess[i+2][j+2] == chess[i+3][j+3] == chess[i+4][j+4] == 1:
                return True
    for i in range(4,10):
        for j in range(6):
            if chess[i][j] == chess[i-1][j+1] == chess[i-2][j+2] == chess[i-3][j+3] == chess[i-4][j+4] == 1:
                return True
    return False


def Lose(chess):
    for i in range(6):
        for j in range(6):
            if chess[i][j] == chess[i+1][j] == chess[i+2][j] == chess[i+3][j] == chess[i+4][j] == 2:
                return True
            if chess[i][j] == chess[i][j+1] == chess[i][j+2] == chess[i][j+3] == chess[i][j+4] == 2:
                return True
            if chess[i][j] == chess[i+1][j+1] == chess[i+2][j+2] == chess[i+3][j+3] == chess[i+4][j+4] == 2:
                return True
    for i in range(4,10):
        for j in range(6):
            if chess[i][j] == chess[i-1][j+1] == chess[i-2][j+2] == chess[i-3][j+3] == chess[i-4][j+4] == 2:
                return True
    return False




def main():
    #initBoardandChess
    initBoard()
    chess = initChess()


    while True:

        #该循环选择放置位置
        while True:
            try:
                x, y = map(int, input("你的回合:").split())
            except:
                print("格式错误！请重新输入！")
                continue
            if x<0 or x>10 or y<0 or y>10:
                print("超出边界")
            elif chess[x][y]!= 0:
                print("该位置已有棋子")
            else:
                break


        blackChess(x,y)
        chess[x][y] = 1

        if Win(chess):
            print("you Win")
            break

        while True:
            m = int(random.random()*10)
            n = int(random.random()*10)
            if m<0 or n<0 or m>10 or n>10:
                continue
            elif chess[m][n] == 1 or chess[m][n] == 2:
                continue
            else:
                whiteChess(m,n)
                chess[m][n] = 2
                break

        if Lose(chess):
            print("you Lose")
            break




    t.done()





main()
