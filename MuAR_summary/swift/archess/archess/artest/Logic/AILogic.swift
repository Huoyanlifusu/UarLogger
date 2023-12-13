//
//  AILogic.swift
//  archess
//
//  Created by 张裕阳 on 2023/2/14.
//
import Foundation


struct AIChessInfo {
    static var indexDict = [[0,0]:0, [0,1]:0, [0,2]:0, [0,3]:0, [0,4]:0, [0,5]:0, [0,6]:0, [0,7]:0, [0,8]:0,
                            [1,0]:0, [1,1]:0, [1,2]:0, [1,3]:0, [1,4]:0, [1,5]:0, [1,6]:0, [1,7]:0, [1,8]:0,
                            [2,0]:0, [2,1]:0, [2,2]:0, [2,3]:0, [2,4]:0, [2,5]:0, [2,6]:0, [2,7]:0, [2,8]:0,
                            [3,0]:0, [3,1]:0, [3,2]:0, [3,3]:0, [3,4]:0, [3,5]:0, [3,6]:0, [3,7]:0, [3,8]:0,
                            [4,0]:0, [4,1]:0, [4,2]:0, [4,3]:0, [4,4]:0, [4,5]:0, [4,6]:0, [4,7]:0, [4,8]:0,
                            [5,0]:0, [5,1]:0, [5,2]:0, [5,3]:0, [5,4]:0, [5,5]:0, [5,6]:0, [5,7]:0, [5,8]:0,
                            [6,0]:0, [6,1]:0, [6,2]:0, [6,3]:0, [6,4]:0, [6,5]:0, [6,6]:0, [6,7]:0, [6,8]:0,
                            [7,0]:0, [7,1]:0, [7,2]:0, [7,3]:0, [7,4]:0, [7,5]:0, [7,6]:0, [7,7]:0, [7,8]:0,
                            [8,0]:0, [8,1]:0, [8,2]:0, [8,3]:0, [8,4]:0, [8,5]:0, [8,6]:0, [8,7]:0, [8,8]:0]
    static var IndexArray = [[Int]](repeating: [Int](repeating: 0, count: SinglePlayerGameInfo.columnNum), count: SinglePlayerGameInfo.rowNum)
    
    static var nextStep: [Int] = [0, 0]
    
    static var AIChessColor = 0
    
    static var AIChessNum = 0
    
    static let searchDepth = 3
    
    static let attackRatio: Float = 1.0 // 大于1防守型AI 小于1进攻型AI
    
    static let shapeScore = [[0,0,1,2,0]: 20, [0,0,2,1,0]: 20, [0,1,2,0,0]: 20, [0,2,1,0,0]: 20, //眠1
                             [0,1,1,2,0]: 100, [0,2,2,1,0]: 100, [0,1,2,2,0]: 100, [0,2,1,1,0]: 100, //眠2
                             [0,1,1,0,0]: 200, [0,2,2,0,0]: 200, [0,0,1,1,0]: 200, [0,0,2,2,0]: 200, //活2
                             [2,1,1,1,0]: 400, [1,2,2,2,0]: 400, [0,1,1,1,2]: 400, [0,2,2,2,1]: 400, //眠3
                             [0,1,1,1,0]: 1000, [0,2,2,2,0]: 1000, //活3
                             [2,1,1,1,1]: 8000, [1,2,2,2,2]: 8000, [1,1,1,1,2]: 8000, [2,2,2,2,1]: 8000, //眠4
                             [0,1,1,1,1]: 10000, [0,2,2,2,2]: 10000, [1,1,1,1,0]: 10000, [2,2,2,2,0]: 10000, //活4
                             [1,1,1,1,1]: 99999, [2,2,2,2,2]: 99999 //活5
    ]
}

struct SinglePlayerGameInfo {
    static let columnNum = 9
    static let rowNum = 9
    
    static var level = 2 //1-简单，2-中等，3-困难
}

//哈希表存放棋子信息
func resetAIChessInfo() {
    AIChessInfo.nextStep = [0,0]
    AIChessInfo.indexDict = [[0,0]:0, [0,1]:0, [0,2]:0, [0,3]:0, [0,4]:0, [0,5]:0, [0,6]:0, [0,7]:0, [0,8]:0,
                             [1,0]:0, [1,1]:0, [1,2]:0, [1,3]:0, [1,4]:0, [1,5]:0, [1,6]:0, [1,7]:0, [1,8]:0,
                             [2,0]:0, [2,1]:0, [2,2]:0, [2,3]:0, [2,4]:0, [2,5]:0, [2,6]:0, [2,7]:0, [2,8]:0,
                             [3,0]:0, [3,1]:0, [3,2]:0, [3,3]:0, [3,4]:0, [3,5]:0, [3,6]:0, [3,7]:0, [3,8]:0,
                             [4,0]:0, [4,1]:0, [4,2]:0, [4,3]:0, [4,4]:0, [4,5]:0, [4,6]:0, [4,7]:0, [4,8]:0,
                             [5,0]:0, [5,1]:0, [5,2]:0, [5,3]:0, [5,4]:0, [5,5]:0, [5,6]:0, [5,7]:0, [5,8]:0,
                             [6,0]:0, [6,1]:0, [6,2]:0, [6,3]:0, [6,4]:0, [6,5]:0, [6,6]:0, [6,7]:0, [6,8]:0,
                             [7,0]:0, [7,1]:0, [7,2]:0, [7,3]:0, [7,4]:0, [7,5]:0, [7,6]:0, [7,7]:0, [7,8]:0,
                             [8,0]:0, [8,1]:0, [8,2]:0, [8,3]:0, [8,4]:0, [8,5]:0, [8,6]:0, [8,7]:0, [8,8]:0 ]
    AIChessInfo.IndexArray = [[Int]](repeating: [Int](repeating: 0, count: SinglePlayerGameInfo.columnNum), count: SinglePlayerGameInfo.rowNum)
    AIChessInfo.AIChessColor = 0
    AIChessInfo.AIChessNum = 0
}

func AIInitial(with level: Int) {
    //AI下棋难度
    switch level {
    case 1:
        EasyAI()
        return
    case 2:
        MediumAI()
    case 3:
        HardAI()
    default:
        fatalError("cannot initial ai without a AIlevel")
    }
}

func EasyAI() {}
func HardAI() {}
func MediumAI() {}


func AIstep() -> [Int]? {
    let value = negaMax(depth: AIChessInfo.searchDepth, alpha: -99999, beta: 99999, isAI: true)
    AIChessInfo.indexDict[AIChessInfo.nextStep] = AIChessInfo.AIChessColor
    AIChessInfo.IndexArray[AIChessInfo.nextStep[0]][AIChessInfo.nextStep[1]] = AIChessInfo.AIChessColor
    if isAIWin(AIChessInfo.IndexArray) {
        DispatchQueue.main.async {
            print("AI获胜！")
        }
        return nil
    }
    return AIChessInfo.nextStep
}


//极大极小值算法
func negaMax(depth: Int, alpha: Int, beta: Int, isAI: Bool) -> Int {
    var newAlpha: Int = alpha
    if depth == 0 {
        return evaluate()
    }
    //寻找空白点
    for (key, value) in AIChessInfo.indexDict {
        if value == 1 || value == 2 {
            continue
        }
        if hasNeibour(for: key) == false {
            continue
        }
        if isAI {
            AIChessInfo.indexDict.updateValue(AIChessInfo.AIChessColor, forKey: key)
            AIChessInfo.IndexArray[key[0]][key[1]] = AIChessInfo.AIChessColor
        } else {
            AIChessInfo.indexDict.updateValue(MyChessInfo.myChessColor, forKey: key)
            AIChessInfo.IndexArray[key[0]][key[1]] = MyChessInfo.myChessColor
        }
        let value = -negaMax(depth: depth-1, alpha: -beta, beta: -newAlpha, isAI: !isAI)
        AIChessInfo.indexDict.updateValue(0, forKey: key)
        AIChessInfo.IndexArray[key[0]][key[1]] = 0
        if isAI {
            if value > newAlpha {
                newAlpha = value
                
                if depth == AIChessInfo.searchDepth {
                    AIChessInfo.nextStep = key
                }
            }
        } else {
            if value >= beta {
                AIChessInfo.nextStep = key
                return beta
            }
        }
        
    }
    
    return newAlpha
}

//计算权重综合
func evaluate() -> Int {
    
    var AIScore: Int = 0
    var PlayerScore: Int = 0
    //更新AI棋子权重
    for (key, value) in AIChessInfo.indexDict {
        if value == 0 {
            continue
        } else if value == AIChessInfo.AIChessColor {
            AIScore += addWeight(with: 1, and: key)
            AIScore += addWeight(with: 2, and: key)
            AIScore += addWeight(with: 3, and: key)
            AIScore += addWeight(with: 4, and: key)
        } else {
            PlayerScore += addWeight(with: 1, and: key)
            PlayerScore += addWeight(with: 2, and: key)
            PlayerScore += addWeight(with: 3, and: key)
            PlayerScore += addWeight(with: 4, and: key)
        }
    }
    
    
    let totalScore = AIScore - Int(Float(PlayerScore) * AIChessInfo.attackRatio)
    return totalScore
}

func addWeight(with direction: Int, and index: [Int]) -> Int {
    if index[0] < 2 || index[0] > 6 || index[1] < 2 || index[1] > 6 {
        return 0
    }
    
    switch direction {
    case 1:
        //横排检索
        let index_l1 = [index[0]-1, index[1]]
        let index_l2 = [index[0]-2, index[1]]
        let index_r1 = [index[0]+1, index[1]]
        let index_r2 = [index[0]+2, index[1]]
        let chessNearby: [Int] = [AIChessInfo.indexDict[index_l2]!,
                                  AIChessInfo.indexDict[index_l1]!,
                                  AIChessInfo.indexDict[index]!,
                                  AIChessInfo.indexDict[index_r1]!,
                                  AIChessInfo.indexDict[index_r2]!]
        if AIChessInfo.shapeScore[chessNearby] != nil {
            guard let addScore = AIChessInfo.shapeScore[chessNearby] else { fatalError("score数据错误") }
            return addScore
        }
        return 0
    case 2:
        //竖排检索
        let index_d1 = [index[0], index[1]-1]
        let index_d2 = [index[0], index[1]-2]
        let index_u1 = [index[0], index[1]+1]
        let index_u2 = [index[0], index[1]+2]
        let chessNearby: [Int] = [AIChessInfo.indexDict[index_d2]!,
                                  AIChessInfo.indexDict[index_d1]!,
                                  AIChessInfo.indexDict[index]!,
                                  AIChessInfo.indexDict[index_u1]!,
                                  AIChessInfo.indexDict[index_u2]!]
        if AIChessInfo.shapeScore[chessNearby] != nil {
            guard let addScore = AIChessInfo.shapeScore[chessNearby] else { fatalError("score数据错误") }
            return addScore
        }
        return 0
    case 3:
        //左上-右下检索
        let index_d1 = [index[0]+1, index[1]-1]
        let index_d2 = [index[0]+2, index[1]-2]
        let index_u1 = [index[0]-1, index[1]+1]
        let index_u2 = [index[0]-2, index[1]+2]
        let chessNearby: [Int] = [AIChessInfo.indexDict[index_d2]!,
                                  AIChessInfo.indexDict[index_d1]!,
                                  AIChessInfo.indexDict[index]!,
                                  AIChessInfo.indexDict[index_u1]!,
                                  AIChessInfo.indexDict[index_u2]!]
        if AIChessInfo.shapeScore[chessNearby] != nil {
            guard let addScore = AIChessInfo.shapeScore[chessNearby] else { fatalError("score数据错误") }
            return addScore
        }
        return 0
    case 4:
        //右上-左下检索
        let index_d1 = [index[0]-1, index[1]-1]
        let index_d2 = [index[0]-2, index[1]-2]
        let index_u1 = [index[0]+1, index[1]+1]
        let index_u2 = [index[0]+2, index[1]+2]
        let chessNearby: [Int] = [AIChessInfo.indexDict[index_d2]!,
                                  AIChessInfo.indexDict[index_d1]!,
                                  AIChessInfo.indexDict[index]!,
                                  AIChessInfo.indexDict[index_u1]!,
                                  AIChessInfo.indexDict[index_u2]!]
        if AIChessInfo.shapeScore[chessNearby] != nil {
            guard let addScore = AIChessInfo.shapeScore[chessNearby] else { fatalError("score数据错误") }
            return addScore
        }
        return 0
    default:
        return 0
    }
}

//判断棋子旁有没有邻居
func hasNeibour(for key: [Int]) -> Bool {
    for i in -1...1 {
        for j in -1...1 {
            if i==j && i==0 {
                continue
            } else {
                let newkey: [Int] = [key[0]+i,key[1]+j]
                if AIChessInfo.indexDict[newkey] == 1 || AIChessInfo.indexDict[newkey] == 2 {
                    return true
                }
            }
        }
    }
    return false
}

func isAIWin(_ indexArray: [[Int]]) -> Bool {
    for i in 0..<indexArray.count {
        for j in 0..<indexArray[i].count {
            if i < indexArray.count - 4 {
                if indexArray[i][j] == AIChessInfo.AIChessColor && indexArray[i+1][j] == indexArray[i+2][j]
                    && indexArray[i+2][j] == indexArray[i+3][j] && indexArray[i+3][j] == indexArray[i+4][j]
                    && indexArray[i+4][j] == indexArray[i][j] {
                    return true
                }
            }
            if j < indexArray.count - 4 {
                if indexArray[i][j] == AIChessInfo.AIChessColor && indexArray[i][j+1] == indexArray[i][j+2]
                    && indexArray[i][j+2] == indexArray[i][j+3] && indexArray[i][j+3] == indexArray[i][j+4]
                    && indexArray[i][j+4] == indexArray[i][j] {
                    return true
                }
            }
            if i < indexArray.count - 4 && j < indexArray.count - 4 {
                if indexArray[i][j] == AIChessInfo.AIChessColor && indexArray[i+1][j+1] == indexArray[i+2][j+2]
                    && indexArray[i+2][j+2] == indexArray[i+3][j+3] && indexArray[i+3][j+3] == indexArray[i+4][j+4]
                    && indexArray[i+4][j+4] == indexArray[i][j] {
                    return true
                }
            }
            if i >= 4 && j < indexArray.count - 4 {
                if indexArray[i][j] == AIChessInfo.AIChessColor && indexArray[i-1][j+1] == indexArray[i-2][j+2]
                    && indexArray[i-2][j+2] == indexArray[i-3][j+3] && indexArray[i-3][j+3] == indexArray[i-4][j+4]
                    && indexArray[i-4][j+4] == indexArray[i][j] {
                    return true
                }
            }
        }
    }
    return false
}

func isMeWin(_ indexArray: [[Int]]) -> Bool {
    for i in 0..<indexArray.count {
        for j in 0..<indexArray[i].count {
            if i < indexArray.count - 4 {
                if indexArray[i][j] == MyChessInfo.myChessColor && indexArray[i+1][j] == indexArray[i+2][j]
                    && indexArray[i+2][j] == indexArray[i+3][j] && indexArray[i+3][j] == indexArray[i+4][j]
                    && indexArray[i+4][j] == indexArray[i][j] {
                    return true
                }
            }
            if j < indexArray.count - 4 {
                if indexArray[i][j] == MyChessInfo.myChessColor && indexArray[i][j+1] == indexArray[i][j+2]
                    && indexArray[i][j+2] == indexArray[i][j+3] && indexArray[i][j+3] == indexArray[i][j+4]
                    && indexArray[i][j+4] == indexArray[i][j] {
                    return true
                }
            }
            if i < indexArray.count - 4 && j < indexArray.count - 4 {
                if indexArray[i][j] == MyChessInfo.myChessColor && indexArray[i+1][j+1] == indexArray[i+2][j+2]
                    && indexArray[i+2][j+2] == indexArray[i+3][j+3] && indexArray[i+3][j+3] == indexArray[i+4][j+4]
                    && indexArray[i+4][j+4] == indexArray[i][j] {
                    return true
                }
            }
            if i >= 4 && j < indexArray.count - 4 {
                if indexArray[i][j] == MyChessInfo.myChessColor && indexArray[i-1][j+1] == indexArray[i-2][j+2]
                    && indexArray[i-2][j+2] == indexArray[i-3][j+3] && indexArray[i-3][j+3] == indexArray[i-4][j+4]
                    && indexArray[i-4][j+4] == indexArray[i][j] {
                    return true
                }
            }
        }
    }
    return false
}


func updatedAIIndexArray(indexOfX: Int, indexOfY: Int, with ChessColor: Int) {
    AIChessInfo.IndexArray[4+indexOfX][4+indexOfY] = ChessColor
    let index = [indexOfX+4, indexOfY+4]
    AIChessInfo.indexDict[index] = ChessColor
    print("\(AIChessInfo.indexDict)")
    if ChessColor == MyChessInfo.myChessColor {
        MyChessInfo.myChessNum += 1
    } else {
        AIChessInfo.AIChessNum += 1
    }
}
