//
//  reviewParse.swift
//
//
//  Created by Jeremy Cao on 11/11/22.
//

import Foundation
import NaturalLanguage

//let reviews = ["Absolutely terrible service with horrible food", "Best food in existence", "I don't know what is happening", "Horrible experience, my dog literally died after I fed them them my chocolate pudding 0/10 just disgraceful"]

//var id = ""
var domainURLString = ""

var reviewList = [String]()

struct YelpAPIRev {
    let apikey = "80aSnHnyHk_OeP8nV1soG9yi6vkMnprpZLNQ75M-wpAKqYgiwgpEXmSToC7MV7d9Wo_PD8pbYMHQ_tLR5lG0qejq8MTZwenFxGWQso6gaHOg3d4xE4gZaKJaCTZXY3Yx"
    
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    mutating func setID(id: String) -> Void {
        if id != "" {
            domainURLString = "https://api.yelp.com/v3/businesses/f-m7-hyFzkf0HSEeQ2s-9A/reviews"
        } else {
            domainURLString = "https://api.yelp.com/v3/businesses/\(id)/reviews"
        }
        self.getRev() // get new set of restaurants based on term
    }
    
    fileprivate func getRev()->Void {
        let url = URL(string: domainURLString)
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(apikey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                let _ = print("DataTask error: " + error.localizedDescription + "\n")
            }
            restaurants.removeAll() // clear restaurants from previous query
            do {
                let jsonRev = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]

                let _ = print(">>>>", jsonRev, #line,"<<<<")

                if let reviews = jsonRev["reviews"] as? [NSDictionary] {
                    print("Reviews")
                    print(reviews)
                    for r in reviews {
                        reviewList.append(r["text"] as! String)
                    }
                }
            } catch {
                let _ = print("caught")
            }
            //callComplete = true
            //callLock.broadcast() //wake up waiting threads
        }.resume()
    }

        
}



func reviewTag(reviews: [String]) -> [String] {
    var corpus = " "

    for review in reviews {
        corpus = corpus + review
        corpus = corpus + " "
    }
    //let corpus = reviews[0] + " " + reviews[1] + " " + reviews[2]
    //var corpusSplit = corpus.split(separator: " ")

    //print(corpusSplit)
    // Create the POS tagger instance
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = corpus

    // Set options to omit whitespace and any punctuation; also set the range of the tagger to be length of corpus
    let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinContractions]

    var adjectives = [String]()

    tagger.enumerateTags(in: corpus.startIndex ..< corpus.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
        if let tag = tag {
            if tag.rawValue == "Adjective" {
                adjectives.append(("\(corpus[tokenRange])").lowercased())
            }
            //print("\(corpus[tokenRange]): \(tag.rawValue)")
        }
        return true
    }
    
    
    return adjectives
}

func reviewRank(adjectives: [String]) -> Any{
    var counter = 0
    var adjInfo:[String:Int] = [:]

    for word in adjectives {
        counter = adjectives.filter{$0 == word}.count
        adjInfo["\(word)"] = counter * (1 +  (word.count/5))
    }

    //print(adjInfo)

    let ranking = adjInfo.sorted {$0.1 > $1.1}
    //print(type(of: ranking))
    //return ranking
    //return (ranking[0].key, ranking[1].key, ranking[2].key)
    return ranking

    //print(ranking[0].key, ranking[1].key, ranking[2].key)
}

func retRev(id: String)->[String] {
    var Rev = YelpAPIRev()
    Rev.setID(id: id)
    Rev.getRev()
    let parsedCorpus = reviewTag(reviews: reviewList)
    print("corpus")
    print(parsedCorpus)
    let results = reviewRank(adjectives: parsedCorpus) as! [String]
    return results
}

//let parsedCorpus = reviewTag(reviews: reviews)
//let results = reviewRank(adjectives: parsedCorpus)

//return results
//print("REVIEW PARSE RESULTS: ", results)


