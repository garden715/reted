//
//  SpeechTableViewController.swift
//  reted
//
//  Created by seojungwon on 2016. 11. 30..
//  Copyright © 2016년 seojungwon. All rights reserved.
//

import UIKit
import Firebase

private let SpeechTableViewCellIdentifier = "Speech Cell"

class SpeechTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var levelController: UISegmentedControl!
    @IBOutlet weak var navigation: UINavigationItem!
    @IBOutlet weak var clientTable: UITableView!
    
    var videos: [FIRDataSnapshot]! = []
    var speeches : [Speech]! = []
    var filteredSpeeches : [Speech]! = []
    var ref: FIRDatabaseReference!

    fileprivate var _refHandle: FIRDatabaseHandle!
    
    @IBAction func selectedSegmentedController(_ sender: Any) {
        self.filteredSpeeches.removeAll()
        
        for speech : Speech in speeches {
            let grageOfSpeech = speech.grade - 1
            if levelController.selectedSegmentIndex == grageOfSpeech {
                filteredSpeeches.append(speech)
            }
        }
        self.clientTable.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clientTable.register(UINib(nibName: "SpeechTableViewCell", bundle: nil), forCellReuseIdentifier: SpeechTableViewCellIdentifier)
        
        configureDatabase()

        navigationController?.navigationBar.setBottomBorderColor(color: .red, height: 3.0)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.ref.child("speech").removeObserver(withHandle: _refHandle)
    } 
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        
        _refHandle = self.ref.child("speech").observe(FIRDataEventType.value, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
            let videosEnumerator = snapshot.children
            while let video = videosEnumerator.nextObject() as? FIRDataSnapshot {
                if let videoDict = video.value as? Dictionary<String, AnyObject> {
                    let insertedSpeech = Speech()
                    insertedSpeech.setValuesForKeys(videoDict);
                    strongSelf.videos.append(video)
                    strongSelf.speeches.append(insertedSpeech)
                    strongSelf.filteredSpeeches.append(insertedSpeech)
                    strongSelf.clientTable.insertRows(at: [IndexPath(row: strongSelf.videos.count-1, section: 0)], with: .automatic)
                }
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.videos.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.clientTable.dequeueReusableCell(withIdentifier: SpeechTableViewCellIdentifier, for: indexPath) as! SpeechTableViewCell
        
        // Unpack message from Firebase DataSnapshot

        let speech : Speech! = self.filteredSpeeches[indexPath.row]
        let name = speech.name as String!
        let title = speech.title as String!
        
        cell.activitytIndicator.startAnimating()
        cell.titleLabel.text = title
        cell.nameLabel.text = name
        cell.thumbnail.image = UIImage(named: "ic_account_circle")
        
        DispatchQueue.global(qos: .background).async {
            let photoURL = speech.img
            let url = URL(string: photoURL)
            let data = try? Data(contentsOf: url!)
            
            DispatchQueue.main.async {
                if data != nil {
                    cell.thumbnail.image = UIImage(data: data!)
                    cell.activitytIndicator.stopAnimating()
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Constants.Segues.FpToDetail, sender: speeches[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segues.FpToDetail{
            let vc = segue.destination as! SpeechDetailViewController
            vc.speech = sender as! Speech
        }
    }

    @IBAction func signOut(_ sender: UIBarButtonItem) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            dismiss(animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    func alertMessage(_message:String) {
        let alert = UIAlertController(title: "Alert", message: _message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
}

extension UINavigationBar {
    
    func setBottomBorderColor(color: UIColor, height: CGFloat) {
        let bottomBorderRect = CGRect(x: 0, y: frame.height, width: frame.width, height: height)
        let bottomBorderView = UIView(frame: bottomBorderRect)
        bottomBorderView.backgroundColor = color
        addSubview(bottomBorderView)
    }
}
