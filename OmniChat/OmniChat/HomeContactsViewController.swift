//
//  HomeContactsViewController.swift
//  OmniChat
//
//  Created by Brice Maltby on 6/10/17.
//  Copyright © 2017 Brice Maltby. All rights reserved.
//

import UIKit
import Contacts
import Firebase

class HomeContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var contactsList = [CNContact.init()]
    var contactsWithProfileList = [CNContact.init()]
    //var results = [CNContact.init()]
    var results = [CNContact]()
    var userPhoneNumber = String()
    //var userPhoneNumber = String()
    
    var contactNameToMain = String()
    var contactPhoneToMain = String()
    var receiverUidToMain = String()
    var callerOrReceiver = String()
    var receiverToken = ""
    var roomUid = String()
    var contactPhoneNumerals = String()
    
    @IBOutlet weak var signOutButton: UIBarButtonItem!
    @IBOutlet weak var contactsTableView: UITableView!
    @IBAction func signOutButtonAction(_ sender: Any) {
        
        do {
            try Auth.auth().signOut()
        } catch {
            print("error logging out")
        }
    }
    
    var selectedLanguage = String()
    
    var availableLanguagesDict : Dictionary = ["Dutch":"nl", "Spanish":"es", "Chinese":"zh", "French":"fr", "Italian":"it", "Vietnamese":"vi", "English":"en", "Catalan":"ca", "Korean":"ko", "Romanian":"ro", "Danish":"da", "German":"de", "Portuguese":"pt", "Swedish":"sv", "Arabic":"ar", "Hungarian":"hu", "Japanese":"ja", "Finnish":"fi", "Turkish":"tr", "Polish":"pl", "Indonesian":"id", "Malay":"ms", "Greek":"el", "Czech":"cs", "Croatian":"hr", "Russian":"ru", "Thai":"th", "Slovak":"sk", "Ukrainian":"uk"]
    
    var availableLanguagesArray : Array = ["Dutch", "Spanish", "Chinese", "French", "Italian", "Vietnamese", "English", "Catalan", "Korean", "Romanian", "Danish", "German", "Portuguese", "Swedish", "Arabic", "Hungarian", "Japanese", "Finnish", "Turkish", "Polish", "Indonesian", "Malay", "Greek", "Czech", "Croatian", "Russian", "Thai", "Slovak", "Ukrainian"]
    
    let alertView = UIAlertController(
        title: "Select your language",
        message: "\n\n\n\n\n\n\n\n\n",
        preferredStyle: .alert)
    
    let pickerView = UIPickerView(frame:
        CGRect(x: 0, y: 50, width: 260, height: 162))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener { (Auth, user) in
            if user == nil {
                self.performSegue(withIdentifier: "homeToSignUpView", sender: self)
            }
        }
        
        self.getContacts()
        
        callListener()
        
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        pickerView.backgroundColor = UIColor.white
        alertView.view.addSubview(pickerView)
        
        let action = UIAlertAction(title: "Select", style: UIAlertActionStyle.default, handler:
        {(alert: UIAlertAction!) in
            print("Foo")
            self.languageWasSelected()
        })
        
        alertView.addAction(action)
        
        // Do any additional setup after loading the view.
    }
    
    
    func getUserPhoneNumber(handler:@escaping (_ userPhoneNumber:String?) -> Void ) {
        let dbRef = Database.database().reference()
        dbRef.child("users").child(User.sharedInstance.status()!).child("phoneNumber").observeSingleEvent(of: .value, with: { (snap) in
            let number = snap.value
            handler(String(describing: number))
        })
    }
    
    func getContacts() {
        let store = CNContactStore()
        
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            store.requestAccess(for: .contacts, completionHandler: { (authorized: Bool, error: Error?) -> Void in
                if authorized {
                    self.retrieveContactsWithStore(store: store)
                }
            } )
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            self.retrieveContactsWithStore(store: store)
        }
    }
    
    func retrieveContactsWithStore(store: CNContactStore) {
        do {
            //let groups = try store.groups(matching: nil)
            let containerId = store.defaultContainerIdentifier()
            let predicate = CNContact.predicateForContactsInContainer(withIdentifier: containerId)
            let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactEmailAddressesKey] as [Any]
            
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
            self.contactsList = contacts
            
            getDBPhoneList() { (dbList) -> Void in
                self.contactsWithProfileList = self.findMatches(phoneContacts: self.contactsList, contactStore: store, list: dbList)
                print(self.contactsWithProfileList)
                DispatchQueue.main.async {
                    self.contactsTableView.reloadData()
                }
            }
            
        } catch {
            print(error)
        }
    }
    
    func getDBPhoneList(handler:@escaping (_ list:[String]) -> Void) {
        let ref = Database.database().reference()
        
        ref.child("data").child("phoneNumbers").observe(.value, with: { (snapshot) in
            let count = Int(snapshot.childrenCount)
            var dbPhoneList = [String]()
            
            for childSnap in snapshot.children.allObjects {
                let snap = childSnap as! DataSnapshot
                print(snap)
                
                dbPhoneList.append(snap.key)
                
                if dbPhoneList.count == count {
                    handler([String](dbPhoneList))
                }
            }
        })
    }
    
    func findMatches(phoneContacts:[CNContact], contactStore:CNContactStore, list:[String]) -> [CNContact] {
        
        let request = CNContactFetchRequest(keysToFetch: [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [Any] as! [CNKeyDescriptor])
        
        do {
            try contactStore.enumerateContacts(with: request) { contact, stop in
                for contactListNumber in contact.phoneNumbers {
                    if let cnContactPhoneNumber = ((contact.phoneNumbers.first?.value))?.stringValue {
                        
                        var numerals = self.stringToNumerals(stringPhone: cnContactPhoneNumber)
                        if list.contains(numerals) {
                            self.results.append(contact)
                            return
                        }
                    }
                }
            }
        } catch let enumerateError {
            print(enumerateError.localizedDescription)
        }
        return results
    }
    
    func callListener() {
        let ref = Database.database().reference()
        let userUid = Auth.auth().currentUser?.uid
        
        if userUid != nil {
            ref.child("listener").child(userUid!).child("roomUid").observe(.value, with: { (snap) in
                if snap.exists() {
                    self.roomUid = snap.value as! String
                    
                    ref.child("tokenCreator").child(self.roomUid).child("recipientToken").observe(.value, with: { (snap) in
                        if snap.exists() {
                            let receiverToken = snap.value
                            
                            let incomingCallAlert = UIAlertController(title: "Call from", message: "contact", preferredStyle: UIAlertControllerStyle.alert)
                            
                            incomingCallAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                                print("Handle Ok logic here")
                                self.callerOrReceiver = "receiver"
                                self.receiverToken = receiverToken as! String
                                self.receiverUidToMain = (Auth.auth().currentUser?.uid)!
                                
                                self.present(self.alertView, animated: true, completion: { _ in
                                    self.pickerView.frame.size.width = self.alertView.view.frame.size.width
                                    self.pickerView.reloadAllComponents()
                                })
                            }))
                            
                            incomingCallAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                                print("Handle Cancel Logic here")
                            }))
                            
                            self.present(incomingCallAlert, animated: true, completion: nil)
                        }
                        
                    })
                }
            }, withCancel: { (err) in
                return
            })
            
        }
        
    }
    
    
    func stringToNumerals(stringPhone: String) -> String {
        var numerals = stringPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if numerals.hasPrefix("1") {
            numerals.remove(at: numerals.startIndex)
            return numerals
        } else {
            return numerals
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contactsTableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        
        let contact = self.contactsWithProfileList[indexPath.row]
        let formatter = CNContactFormatter()
        
        let contactName = formatter.string(from: contact)
        let contactPhone = contact.phoneNumbers.first?.value.stringValue
        
        cell.textLabel?.text = contactName
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsWithProfileList.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("row selected")
        
        let contact = self.contactsWithProfileList[indexPath.row]
        let formatter = CNContactFormatter()
        callerOrReceiver = "caller"
        
        let contactName = formatter.string(from: contact)
        let contactPhoneString = contact.phoneNumbers.first?.value.stringValue
        self.contactPhoneNumerals = stringToNumerals(stringPhone: contactPhoneString!)
        
        self.contactNameToMain = String(describing: contactName)
        self.contactPhoneToMain = String(describing: contactPhoneNumerals)
        
        self.present(self.alertView, animated: true, completion: { _ in
            self.pickerView.frame.size.width = self.alertView.view.frame.size.width
            self.pickerView.reloadAllComponents()
        })
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableLanguagesDict.keys.count
    }
    /*
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributedString = NSAttributedString(string: "some string", attributes: [NSForegroundColorAttributeName : UIColor.red])
        return attributedString
    }*/
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return availableLanguagesArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        let language = availableLanguagesArray[selectedRow]
        selectedLanguage = availableLanguagesDict[language]!
        
        
//        let language = availableLanguagesArray[row]
//        selectedLanguage = availableLanguagesDict[language]!
    }
    
    func languageWasSelected() {
        if callerOrReceiver == "caller" {
            let ref = Database.database().reference()
            
            ref.child("data").child("phoneNumbers").child(contactPhoneNumerals).observeSingleEvent(of: .value, with: { (snap) in
                print(snap)
                self.receiverUidToMain = snap.value as! String
                print(self.receiverUidToMain)
                
                self.performSegue(withIdentifier: "homeContactToMain", sender: self)
                
            }) { (err) in
                return
            }
        } else if callerOrReceiver == "receiver" {
            self.performSegue(withIdentifier: "homeContactToMain", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let ref = Database.database().reference()
        
        if callerOrReceiver == "caller" {
            if let destinationViewController = segue.destination as? MainViewController {
                destinationViewController.contactName = contactNameToMain
                destinationViewController.contactPhone = contactPhoneToMain
                destinationViewController.receiverUid = receiverUidToMain
                destinationViewController.callerOrReceiver = callerOrReceiver
                if selectedLanguage == "" {
                    destinationViewController.localLanguage = "nl"
                    destinationViewController.callerLanguage = "nl"
                } else {
                    destinationViewController.localLanguage = selectedLanguage
                    destinationViewController.callerLanguage = selectedLanguage
                }
                
            }
        } else {
            if let destinationViewController = segue.destination as? MainViewController {
                destinationViewController.receiverUid = receiverUidToMain
                destinationViewController.callerOrReceiver = callerOrReceiver
                destinationViewController.receiverToken = receiverToken
                destinationViewController.roomUid = roomUid
                if selectedLanguage == "" {
                    destinationViewController.localLanguage = "nl"
                    destinationViewController.receiverLanguage = "nl"
                } else {
                    destinationViewController.localLanguage = selectedLanguage
                    destinationViewController.receiverLanguage = selectedLanguage
                }
            }
        }
    }
}
