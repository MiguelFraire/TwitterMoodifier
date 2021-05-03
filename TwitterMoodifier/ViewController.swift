//
//  ViewController.swift
//  TwitterMoodifier
//
//  Created by Miguel Fraire on 5/1/21.
//

import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    @IBOutlet weak var predictButton: UIButton!
    
    let tweetCount = 100
    let sentimentClassifier: TweetSentimentClassifier = {
        do {
            let config = MLModelConfiguration()
            return try TweetSentimentClassifier(configuration: config)
        } catch {
            print(error)
            fatalError("Couldn't create TweetSentimentClassifier")
        }
    }()
    
    let swifter = Swifter(consumerKey: K.API_KEY, consumerSecret: K.API_SECRET)

    override func viewDidLoad() {
        super.viewDidLoad()
        predictButton.layer.cornerRadius = predictButton.layer.frame.height / 2
    }

    @IBAction func predictPressed(_ sender: Any) {
        if textField.text != nil && textField.text != ""{
            print("IM HERE")
            print(textField.text!)
            //fetchTweets()
        }else {
            alertUser()
        }
    }
    func fetchTweets(){
        if let searchText = textField.text {
            swifter.searchTweet(using: searchText, lang: "en", count: tweetCount, tweetMode: .extended ) { (results, metadata) in
                var tweets = [TweetSentimentClassifierInput]()
                for i in 0..<self.tweetCount{
                    if let tweet = results[i]["full_text"].string {
                        let tweetForClassification = TweetSentimentClassifierInput(text: tweet)
                        tweets.append(tweetForClassification)
                    }
                }
                
                self.makePrediction(with: tweets)

            } failure: { (error) in
                print(error)
            }
        }
    }
    func makePrediction(with tweets: [TweetSentimentClassifierInput]){
        do{
            let predictions = try self.sentimentClassifier.predictions(inputs: tweets)
            var sentimentScore = 0
            for result in predictions{
                switch result.label {
                case "Pos":
                    sentimentScore += 1
                case "Neg":
                    sentimentScore -= 1
                default:
                    continue
                }
            }
            updateUI(with: sentimentScore)

        }catch{
            print("There was an error making a prediction, \(error)")
        }
    }
    func updateUI(with sentimentScore: Int){
        if sentimentScore > 20 {
            self.sentimentLabel.text = "🥰"
        }else if sentimentScore > 10 {
            self.sentimentLabel.text = "😀"
        }else if sentimentScore > 0 {
            self.sentimentLabel.text = "🙂"
        }else if sentimentScore == 0 {
            self.sentimentLabel.text = "😐"
        }else if sentimentScore > -10 {
            self.sentimentLabel.text = "🙁"
        }else if sentimentScore > -20 {
            self.sentimentLabel.text = "😫"
        }else{
            self.sentimentLabel.text = "🤬"
        }
    }
    func retrieveKey(keyType name: String) -> String {
        guard let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
          fatalError("Couldn't find file 'Secrets.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: name) as? String else {
          fatalError("Couldn't find key \(name) in 'Secrets.plist'.")
        }
        return value
    }
    func alertUser() {
        // Create new Alert
        let dialogMessage = UIAlertController(title: "Error", message: "You must type a value that begins with @ or #", preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default)
        
        //Add OK button to a dialog message
        dialogMessage.addAction(ok)
        // Present Alert to
        self.present(dialogMessage, animated: true, completion: nil)
    }
    
}

