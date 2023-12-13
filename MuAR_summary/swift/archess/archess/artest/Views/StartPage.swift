//
//  StartPage.swift
//  archess
//
//  Created by 张裕阳 on 2023/2/16.
//

import UIKit

class StartPage: UIViewController {
    
    private let singlePlayerButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0,
                                            y: 0,
                                            width: StartPageConstants.buttonWidth,
                                            height: StartPageConstants.buttonHeight))
        button.backgroundColor = UIColor.gray
        button.layer.cornerRadius = StartPageConstants.buttonCornerRadius
        button.titleLabel?.font = UIFont(name: "hongleisim-Regular", size: 30)
        
        button.setTitle("单人游戏", for: .normal)
        
        return button
    }()
    
    private let multiPlayerButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0,
                                            y: 0,
                                            width: StartPageConstants.buttonWidth,
                                            height: StartPageConstants.buttonHeight))
        button.backgroundColor = UIColor.gray
        button.layer.cornerRadius = StartPageConstants.buttonCornerRadius
        button.titleLabel?.font = UIFont(name: "hongleisim-Regular", size: 30)
        
        button.setTitle("双人游戏", for: .normal)
        
        return button
    }()
    
    private let gameNameText: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,
                                          y: 0,
                                          width: StartPageConstants.textWidth,
                                          height: StartPageConstants.textHeight))
        
        label.text = "AR五子棋"
        label.font = UIFont(name: "hongleisim-Regular", size: 50)
        label.textAlignment = NSTextAlignment.center
        
        return label
    }()
    
    private let imageView: UIImageView = {
        let image = UIImage(named: "view")
        
        let view = UIImageView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: StartPageConstants.imageSize,
                                             height: StartPageConstants.imageSize))
        view.image = image
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.addSubview(imageView)
        self.view.sendSubviewToBack(imageView)
        self.view.addSubview(gameNameText)
        self.view.addSubview(singlePlayerButton)
        self.view.addSubview(multiPlayerButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageView.frame = CGRect(x: view.bounds.size.width/2 - imageView.frame.width/2 - 300,
                                 y: view.bounds.size.height/2 - imageView.frame.height/2 + 40,
                                 width: StartPageConstants.imageSize,
                                 height: StartPageConstants.imageSize)
        
        singlePlayerButton.frame = CGRect(x: view.bounds.size.width/2 - StartPageConstants.buttonWidth/2,
                                          y: view.bounds.size.height/2 + 150,
                                          width: StartPageConstants.buttonWidth,
                                          height: StartPageConstants.buttonHeight)
        
        multiPlayerButton.frame = CGRect(x: view.bounds.size.width/2 - StartPageConstants.buttonWidth/2,
                                          y: view.bounds.size.height/2 + 250,
                                          width: StartPageConstants.buttonWidth,
                                          height: StartPageConstants.buttonHeight)
        
        gameNameText.frame = CGRect(x: view.bounds.size.width/2 - StartPageConstants.textWidth/2,
                                    y: view.bounds.size.height/2 - 350,
                                    width: StartPageConstants.textWidth,
                                    height: StartPageConstants.textHeight)
        
        singlePlayerButton.addTarget(self, action: #selector(startSinglePlayerMode), for: .touchUpInside)
        multiPlayerButton.addTarget(self, action: #selector(startMultiPlayerMode), for: .touchUpInside)
        
    }
    
    @objc private func startSinglePlayerMode() {
        self.performSegue(withIdentifier: "goToSinglePlayerMode", sender: self)
    }
    
    @objc private func startMultiPlayerMode() {
        self.performSegue(withIdentifier: "goToMultiPlayerMode", sender: self)
    }
    
    struct StartPageConstants {
        static let imageSize: CGFloat = 1000
        
        static let buttonWidth: CGFloat = 160
        static let buttonHeight: CGFloat = 80
        static let buttonCornerRadius: CGFloat = 40
        
        static let textWidth: CGFloat = 300
        static let textHeight: CGFloat = 150
    }
}
