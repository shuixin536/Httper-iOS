//
//  RequestViewController.swift
//  Httper
//
//  Created by 李大爷的电脑 on 06/12/2016.
//  Copyright © 2016 limeng. All rights reserved.
//

import UIKit
import Alamofire

enum DesignColor: Int {
    case background = 0x30363b
    case nagivation = 0x3d4143
}

let urlKeyboardCharacters = [":", "/", "?", "&", ".", "="]

let protocols = ["http", "https"]
let keyboardHeight: CGFloat = 320.0

class RequestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var requestMethodButton: UIButton!
    @IBOutlet weak var protocolLabel: UILabel!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var valueTableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var protocolsSegmentedControl: UISegmentedControl!
    
    var editingTextField: UITextField!
    
    var headerCount = 1, parameterCount = 1
    var method: String = "GET"
    var headers: HTTPHeaders!
    var parameters: Parameters!
    var body: String!
    
    var request: Request?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendButton.layer.borderColor = UIColor.lightGray.cgColor
        setCloseKeyboardAccessoryForSender(sender: urlTextField)
        
        NotificationCenter.default.addObserver(self, selector: #selector(bodyChanged(notification:)), name: NSNotification.Name(rawValue: "bodyChanged"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestMethodButton.setTitle(method, for: .normal)
        
        if request != nil {
            method = request!.method!
            headers = NSKeyedUnarchiver.unarchiveObject(with: request!.headers! as Data) as! HTTPHeaders
            parameters = NSKeyedUnarchiver.unarchiveObject(with: request!.parameters! as Data) as! Parameters
            body = (request!.body == nil) ? nil: String(data: request!.body! as Data, encoding: .utf8)
            
            //Set request method
            requestMethodButton.setTitle(method, for: .normal)
            //Set url
            var url = (request?.url)!
            if url.substring(to: url.index(url.startIndex, offsetBy: protocols[1].characters.count + 3)) == "\(protocols[1])://" {
                url = url.substring(from: url.index(url.startIndex, offsetBy: 8))
                protocolsSegmentedControl.selectedSegmentIndex = 1
                protocolLabel.text = "\(protocols[1])://"
            } else {
                url = url.substring(from: url.index(url.startIndex, offsetBy: 7))
                protocolsSegmentedControl.selectedSegmentIndex = 0
                protocolLabel.text = "\(protocols[0])://"
            }
            urlTextField.text = url
            
            valueTableView.reloadData()
            request = nil
        }
    }
    
    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return headerCount
        case 1:
            return parameterCount
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " "
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30))
            view.backgroundColor = RGB(DesignColor.background.rawValue)
            return view
        }()
        
        //Set name
        let nameLabel: UILabel = {
            let label = UILabel(frame: CGRect(x: 15, y: 0, width: headerView.bounds.size.width - headerView.bounds.size.height, height: headerView.bounds.size.height))
            label.textColor = UIColor.white
            switch section {
            case 0:
                label.text = "Headers"
            case 1:
                label.text = "Parameters"
            case 2:
                label.text = "Body"
            default:
                break
            }
            return label
        }()
        headerView.addSubview(nameLabel)
        
        if section < 2 {
            //Set button
            let addButton: UIButton = {
                let button = UIButton(frame: CGRect(x: tableView.bounds.size.width - 35, y: 0, width: headerView.bounds.size.height, height: headerView.bounds.size.height))
                button.setImage(UIImage.init(named: "add_value"), for: UIControlState.normal)
                button.tag = section
                button.addTarget(self, action: #selector(addNewValue(_:)), for: .touchUpInside)
                return button
            }()
            headerView.addSubview(addButton)
        }

        //Set line
        let lineView: UIView = {
            let view = UILabel(frame: CGRect(x: 15, y: 28, width: headerView.bounds.size.width - 15, height: 1))
            view.backgroundColor = UIColor.lightGray
            return view
        }()
        headerView.addSubview(lineView)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        //Cell is body
        if indexPath.section == 2 {
            cell = tableView.dequeueReusableCell(withIdentifier: "bodyIdentifier", for: indexPath)
            return cell
        }
        
        //Cell is headers or parameters
        cell = tableView.dequeueReusableCell(withIdentifier: "parameterIdentifier", for: indexPath as IndexPath)
        let keyTextField = cell.viewWithTag(1) as! UITextField
        let valueTextField = cell.viewWithTag(2) as! UITextField
        setCloseKeyboardAccessoryForSender(sender: keyTextField)
        setCloseKeyboardAccessoryForSender(sender: valueTextField)
        
        //Set headers if it is not null
        if headers != nil && indexPath.section == 0 {
            for (key, value) in headers {
                keyTextField.text = key
                valueTextField.text = value
            }
        }
        
        //Set parameters if it is not null {
        if parameters != nil && indexPath.section == 1 {
            for (key, value) in parameters {
                keyTextField.text = key
                valueTextField.text = "\(value)"
            }
        }
        return cell
    }
    
    //MARK: - UITextViewDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        editingTextField = textField
        if textField == urlTextField {
            return
        }
        let cell = textField.superview?.superview
        let rect = cell?.convert((cell?.bounds)!, to: self.view)
        let y = (rect?.origin.y)!
        let screenHeight = (self.view.window?.frame.size.height)!
        if y > (screenHeight - keyboardHeight) {
            let offset = keyboardHeight - (screenHeight - y) + (cell?.frame.size.height)!
            UIView.animate(withDuration: 0.5, animations: {
                self.view.frame = CGRect(x: 0, y: -offset, width: self.view.frame.size.width, height: self.view.frame.size.height)
            })
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        })
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "resultSegue" {
            segue.destination.setValue(method, forKey: "method")
            segue.destination.setValue("\(protocolLabel.text!)\(urlTextField.text!)", forKey: "url")
            segue.destination.setValue(headers, forKey: "headers")
            segue.destination.setValue(parameters, forKey: "parameters")
            segue.destination.setValue(body, forKey: "body")
        } else if segue.identifier == "requestBodySegue" {
            segue.destination.setValue(body, forKey: "body")
        } else if segue.identifier == "requestMethodSegue" {
            if editingTextField == nil {
                return
            }
            if editingTextField.isFirstResponder {
                editingTextField.resignFirstResponder()
            }
        }
    }
    
    //MARK: - Action
    @IBAction func deleteValue(_ sender: Any) {
        let cell: UITableViewCell = (sender as! UIView).superview?.superview as! UITableViewCell
        let indexPath = valueTableView.indexPath(for: cell)
        if indexPath?.section == 0 {
            if headerCount > 1 {
                headerCount -= 1
                valueTableView.deleteRows(at: [indexPath!], with: .automatic)
            }
        } else if indexPath?.section == 1 {
            if parameterCount > 1 {
                parameterCount -= 1
                valueTableView.deleteRows(at: [indexPath!], with: .automatic)
            }
        }
    }
    
    @IBAction func chooseProtocol(_ sender: UISegmentedControl) {
        let protocolName = protocols[sender.selectedSegmentIndex]
        protocolLabel.text = "\(protocolName)://"
    }
    
    @IBAction func sendRequest(_ sender: Any) {
        if urlTextField.text == "" {
            showAlert(title: NSLocalizedString("tip_name", comment: ""),
                      content: NSLocalizedString("url_empty", comment: ""),
                      controller: self)
            return
        }
        headers = HTTPHeaders()
        parameters = Parameters()
        for section in 0 ..< 2 {
            for row in 0 ..< valueTableView.numberOfRows(inSection: section) {
                let cell: UITableViewCell = valueTableView.cellForRow(at: IndexPath(row: row, section: section))!
                let keyTextField = cell.viewWithTag(1) as! UITextField
                if keyTextField.text == "" {
                    continue
                }
                let valueTextField = cell.viewWithTag(2) as! UITextField
                if section == 0 {
                    headers.updateValue(valueTextField.text!, forKey: keyTextField.text!)
                } else if section == 1 {
                    parameters.updateValue(valueTextField.text!, forKey: keyTextField.text!)
                }
            }
        }
    
        self.performSegue(withIdentifier: "resultSegue", sender: self)
    }
    
    //MARK: - Service
    func addNewValue(_ sender: AnyObject?) {
        if headerCount + parameterCount == 7 {
            showAlert(title: NSLocalizedString("tip_name", comment: ""),
                      content: NSLocalizedString("value_max", comment: ""),
                      controller: self)
            return
        }
        let section: Int! = sender?.tag
        let indexPath = IndexPath(row: (section == 0) ? headerCount: parameterCount, section: section)
        if section == 0 {
            headerCount += 1
        } else if section == 1 {
            parameterCount += 1
        }
        valueTableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func setCloseKeyboardAccessoryForSender(sender: UITextField) {
        let topView: UIToolbar = {
            let view = UIToolbar.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 35))
            view.barStyle = .black;
            let clearButtonItem = UIBarButtonItem(title: NSLocalizedString("clear_name", comment: ""),
                                                  style: UIBarButtonItemStyle.plain,
                                                  target: self,
                                                  action: #selector(clearTextFeild))
            clearButtonItem.tintColor = UIColor.white
            let spaceButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editFinish))
            doneButtonItem.tintColor = UIColor.white
            
            var items = [clearButtonItem, spaceButtonItem]
            for character in urlKeyboardCharacters {
                items.append(createCharacterBarButtonItem(character: character,
                                                          target: self,
                                                          action: #selector(addCharacter(_:)),
                                                          width: 26))
            }
            items.append(spaceButtonItem)
            items.append(doneButtonItem)
            view.setItems(items, animated: false)
            
            return view
        }()
        
        sender.inputAccessoryView = topView
    }
    
    func editFinish() {
        if editingTextField.isFirstResponder {
            editingTextField.resignFirstResponder()
        }
    }
    
    func clearTextFeild() {
        if editingTextField.isFirstResponder {
            editingTextField.text = ""
        }
    }
    
    func addCharacter(_ sender: UIButton) {
        if editingTextField.isFirstResponder {
            editingTextField.text = editingTextField.text! + (sender.titleLabel?.text)!
        }
    }
    
    func bodyChanged(notification: Notification) {
        body = notification.object as! String
    }

}