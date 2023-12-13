//
//  GameLogic.swift
//  artest
//
//  Created by 张裕阳 on 2023/2/7.
//

import Foundation
import SceneKit


struct MyChessInfo {
    //1 for black ad 2 for white
    static var myChessColor: Int = 0
    //1 先手 2 后手
    static var myChessOrder: Int = 0
    
    static var myChessNum: Int = 0
    
    static var IndexArray = [[Int]](repeating: [Int](repeating: 0, count: 9), count: 9)
    
    static var canIPlaceChess = false
    
    static var couldInit = false
}

func resetMyChessInfo() {
    MyChessInfo.myChessNum = 0
    MyChessInfo.myChessOrder = 0
    MyChessInfo.myChessColor = 0
    MyChessInfo.canIPlaceChess = false
    MyChessInfo.couldInit = false
    MyChessInfo.IndexArray = [[Int]](repeating: [Int](repeating: 0, count: 9), count: 9)
}

func randomlyPickChessOrder() -> Int {
    return Int.random(in: 1...2)
}


func randomlyPickChessColor() ->Int  {
    return Int.random(in: 1...2)
}

func thereIsAChess(indexOfX: Int, indexOfY: Int) -> Bool {
    if MyChessInfo.IndexArray[4+indexOfX][4+indexOfY] == 1 || MyChessInfo.IndexArray[4+indexOfX][4+indexOfY] == 2 {
        return true
    }
    return false
}

func updateIndexArray(indexOfX: Int, indexOfY: Int, with ChessColor: Int) {
    MyChessInfo.IndexArray[4+indexOfX][4+indexOfY] = ChessColor
    MyChessInfo.myChessNum += 1
}


func WhoIsWinner(_ chesses: [[Int]]) -> Int {
    for i in 0..<chesses.count {
        for j in 0..<chesses[i].count {
            if i < chesses.count - 4 {
                if chesses[i][j] == 1 && chesses[i+1][j] == chesses[i+2][j]
                    && chesses[i+2][j] == chesses[i+3][j] && chesses[i+3][j] == chesses[i+4][j]
                    && chesses[i+4][j] == chesses[i][j] {
                    return 1
                }
                if chesses[i][j] == 2 && chesses[i+1][j] == chesses[i+2][j]
                    && chesses[i+2][j] == chesses[i+3][j] && chesses[i+3][j] == chesses[i+4][j]
                    && chesses[i+4][j] == chesses[i][j] {
                    return 2
                }
            }
            if j < chesses.count - 4 {
                if chesses[i][j] == 1 && chesses[i][j+1] == chesses[i][j+2]
                    && chesses[i][j+2] == chesses[i][j+3] && chesses[i][j+3] == chesses[i][j+4]
                    && chesses[i][j+4] == chesses[i][j] {
                    return 1
                }
                if chesses[i][j] == 2 && chesses[i][j+1] == chesses[i][j+2]
                    && chesses[i][j+2] == chesses[i][j+3] && chesses[i][j+3] == chesses[i][j+4]
                    && chesses[i][j+4] == chesses[i][j] {
                    return 2
                }
            }
            if i < chesses.count - 4 && j < chesses.count - 4 {
                if chesses[i][j] == 1 && chesses[i+1][j+1] == chesses[i+2][j+2]
                    && chesses[i+2][j+2] == chesses[i+3][j+3] && chesses[i+3][j+3] == chesses[i+4][j+4]
                    && chesses[i+4][j+4] == chesses[i][j] {
                    return 1
                }
                if chesses[i][j] == 2 && chesses[i+1][j+1] == chesses[i+2][j+2]
                    && chesses[i+2][j+2] == chesses[i+3][j+3] && chesses[i+3][j+3] == chesses[i+4][j+4]
                    && chesses[i+4][j+4] == chesses[i][j] {
                    return 2
                }
            }
            if i >= 4 && j < chesses.count - 4 {
                if chesses[i][j] == 1 && chesses[i-1][j+1] == chesses[i-2][j+2]
                    && chesses[i-2][j+2] == chesses[i-3][j+3] && chesses[i-3][j+3] == chesses[i-4][j+4]
                    && chesses[i-4][j+4] == chesses[i][j] {
                    return 1
                }
                if chesses[i][j] == 2 && chesses[i-1][j+1] == chesses[i-2][j+2]
                    && chesses[i-2][j+2] == chesses[i-3][j+3] && chesses[i-3][j+3] == chesses[i-4][j+4]
                    && chesses[i-4][j+4] == chesses[i][j] {
                    return 2
                }
            }
        }
    }
    return 0
}
