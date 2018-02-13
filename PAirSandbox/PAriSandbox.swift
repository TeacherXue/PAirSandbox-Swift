//
//  PAriSandbox.swift
//  Happy Christmas To LXJ
//
//  Created by xueqiangqiang on 2018/2/12.
//  Copyright © 2018年 xueqiangqiang. All rights reserved.
//

import UIKit

let ASThemeColor = UIColor.init(white: 0.2, alpha: 1.0)
let ASWindowPadding : CGFloat = 20

//MARK: ASFileItem
enum ASFileItemType {
    case ASFileItemUp
    case ASFileItemDirectory
    case ASFileItemFile
}

class ASFileItem : NSObject {
    var name : String = ""
    var path : NSString = ""
    var type : ASFileItemType!
}

//MARK: PAirSandboxCell
class PAirSandboxCell : UITableViewCell {
    
    var lbName : UILabel?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        let cellWidth = UIScreen.main.bounds.size.width - 2*ASWindowPadding
        
        self.lbName = UILabel()
        self.lbName?.backgroundColor = UIColor.clear
        self.lbName?.font = UIFont.systemFont(ofSize: 13)
        self.lbName?.textAlignment = .left
        self.lbName?.frame = CGRect(x: 10, y: 30, width: cellWidth - 20, height: 15)
        self.lbName?.textColor = UIColor.black
        self.addSubview(self.lbName!)
        
        let line : UIView = UIView()
        line.backgroundColor = ASThemeColor
        line.frame = CGRect(x: 10, y: 47, width: cellWidth - 20, height: 1)
    }

    func renderWithItem(item : ASFileItem) {
        self.lbName?.text = item.name
    }
}

//MARK: ASViewController
class ASViewController : UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    var tableView : UITableView!
    var btnClose : UIButton!
    var items : [ASFileItem] = []
    var rootPath : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareCtrl()
        self.loadPath(filePaht: "")
    }
    
    func prepareCtrl() {
        self.view.backgroundColor = UIColor.white
        
        self.btnClose = UIButton()
        self.view.addSubview(btnClose)
        self.btnClose.backgroundColor = ASThemeColor
        self.btnClose.setTitleColor(UIColor.white, for: .normal)
        self.btnClose.setTitle("Close", for: .normal)
        self.btnClose.addTarget(self, action: #selector(btnCloseClick), for: .touchUpInside)
        
        self.tableView = UITableView()
        self.view.addSubview(self.tableView)
        self.tableView.backgroundColor = UIColor.white
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.rootPath = NSHomeDirectory()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let viewWidth : CGFloat = UIScreen.main.bounds.size.width - 2*ASWindowPadding
        let closeWidth : CGFloat = 60
        let closeHeight : CGFloat = 28
        
        self.btnClose.frame = CGRect(x: viewWidth - closeWidth - 4, y: 4, width: closeWidth, height: closeHeight)
        
        var tableFrame = self.view.frame
        tableFrame.origin.y += (closeHeight+4)
        tableFrame.size.height -= (closeHeight+4)
        self.tableView.frame = tableFrame
    }
    
    @objc func btnCloseClick(){
        self.view.window?.isHidden = true
    }
    
    func loadPath(filePaht: String) {
        
        var files : [ASFileItem] = []
        
        let fm = FileManager.default
        
        var targetPath : NSString = filePaht as NSString
        if targetPath.length == 0 || targetPath as String == self.rootPath {
            targetPath = self.rootPath as NSString
        }else {
            let file = ASFileItem()
            file.name = "🔙.."
            file.type = ASFileItemType.ASFileItemUp
            file.path = filePaht as NSString
            files.append(file)
        }
        
        do {
            let paths : [NSString] = try fm.contentsOfDirectory(atPath: targetPath as String) as [NSString]
            
            for path in paths {
                if path.lastPathComponent.hasPrefix(".") {
                    continue
                }
                
                var isDir: ObjCBool = ObjCBool(false)
                let fullPath = targetPath.appendingPathComponent(path as String)
                fm.fileExists(atPath: fullPath, isDirectory: &isDir)
                
                let file = ASFileItem()
                file.path = fullPath as NSString
                if isDir.boolValue {
                    file.type = ASFileItemType.ASFileItemDirectory
                    file.name = "📁" + (path as String)
                }else {
                    file.type = ASFileItemType.ASFileItemFile
                    file.name = "📄" + (path as String)
                }
                files.append(file)
            }
            
            self.items = files
            self.tableView.reloadData()
        }catch{
            
        }

    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row > self.items.count - 1 {
            return UITableViewCell()
        }
        
        let item = self.items[indexPath.row]
        
        let cellIdentifier = "PAirSandboxCell"
        var  cell  = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? PAirSandboxCell
        
        if (cell == nil) {
            cell = PAirSandboxCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        
        cell?.renderWithItem(item: item)
        
        return cell!
    }
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > self.items.count - 1 {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        let item = self.items[indexPath.row]
        
        if item.type == ASFileItemType.ASFileItemUp {
            self.loadPath(filePaht: item.path.deletingLastPathComponent)
        }else if item.type == ASFileItemType.ASFileItemFile {
            self.sharePath(path: item.path)
        }else if item.type == ASFileItemType.ASFileItemDirectory {
            self.loadPath(filePaht: item.path as String)
        }
    }
    
    func sharePath(path : NSString) {
        let url = NSURL.fileURL(withPath: path as String)
        let objectsToShare = [url]
        
        let controller : UIActivityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        let excludedActivities = [UIActivityType.postToTwitter, UIActivityType.postToFacebook,
                                  UIActivityType.postToWeibo,
                                  UIActivityType.message, UIActivityType.mail,
                                  UIActivityType.print, UIActivityType.copyToPasteboard,
                                  UIActivityType.assignToContact, UIActivityType.saveToCameraRoll,
                                  UIActivityType.addToReadingList, UIActivityType.postToFlickr,
                                  UIActivityType.postToVimeo, UIActivityType.postToTencentWeibo]
        
        controller.excludedActivityTypes = excludedActivities
        
        self.present(controller, animated: true, completion: nil)
    }
    
}

//MARK: PAirSandbox
class PAriSandbox: NSObject {
    var window : UIWindow!
    var ctrl : ASViewController!
    
    static let shared = PAriSandbox.init()
    private override init(){}
    
    func enableSwipe() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDetected))
        swipeGesture.numberOfTouchesRequired = 1
        swipeGesture.direction = .left
        UIApplication.shared.keyWindow?.addGestureRecognizer(swipeGesture)
    }
    
    @objc func onSwipeDetected() {
        self.showSandboxBrowser()
    }
    
    func showSandboxBrowser() {
        if self.window == nil {
            self.window = UIWindow()
            var keyFrame = UIScreen.main.bounds
            keyFrame.origin.y += 64
            keyFrame.size.height -= 64
            self.window.frame = keyFrame.insetBy(dx: ASWindowPadding, dy: ASWindowPadding)
            self.window.backgroundColor = UIColor.white
            self.window.layer.borderColor = ASThemeColor.cgColor
            self.window.layer.borderWidth = 2.0
            self.window.windowLevel = UIWindowLevelStatusBar
            
            self.ctrl = ASViewController()
            self.window.rootViewController = self.ctrl
        }
        self.window.isHidden = false
    }
}
