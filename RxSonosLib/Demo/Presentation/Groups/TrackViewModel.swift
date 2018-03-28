//
//  TrackViewModel.swift
//  Demo App
//
//  Created by Stefan Renne on 27/03/2018.
//  Copyright © 2018 Uberweb. All rights reserved.
//

import UIKit
import RxSwift
import RxSonosLib

class TrackViewModel {
    private let track: Track
    init(track: Track) {
        self.track = track
    }
    
    lazy var description: String = {
        var description = track.title
        if let artist = track.artist {
            description += "\n" + artist
            if let album = track.album {
                description += "\n" + album
            }
        }
        return description
    }()
    
    lazy var image: Observable<UIImage?> = {
        guard let url = track.imageUri else { return Observable.just(nil) }
        
        return Observable<UIImage?>.create({ (observer) -> Disposable in
            let task = URLSession.shared.dataTask(with: URLRequest(url: url), completionHandler: { (data, response, error) in
                if let data = data, let image = UIImage(data: data) {
                    observer.onNext(image)
                    observer.onCompleted()
                } else if let error = error {
                    observer.onError(error)
                }
            })
            task.resume()
            
            return Disposables.create()
        })
    }()
    
    lazy var progressTime: Observable<String?> = {
        guard track.duration > 0 else { return Observable.just(nil) }
        return track.time.asObservable().map({ $0.toTimeString() })
    }()
    
    lazy var remainingTime: Observable<String?> = {
        guard track.duration > 0 else { return Observable.just(nil) }
        return track.time.asObservable().map({
            let remainingTime = self.track.duration - $0
            guard remainingTime > 0 else { return "0:00" }
            return "-" + remainingTime.toTimeString()
        })
    }()
    
    lazy var trackProgress: Observable<Float> = {
        return track.time.asObservable().map({ Float($0) / Float(self.track.duration) })
    }()
}

fileprivate extension Int {
    func toTimeString() -> String {
        var totalSeconds = self
        let totalHours = totalSeconds / (60 * 60)
        totalSeconds -= totalHours * 60 * 60
        let totalMinutes = totalSeconds / 60
        totalSeconds -= totalMinutes * 60
        
        if totalHours > 0 {
            return "\(totalHours):" + String(format: "%02d", totalMinutes) + ":" + String(format: "%02d", totalSeconds)
        } else {
            return "\(totalMinutes):" + String(format: "%02d", totalSeconds)
        }
    }
}
