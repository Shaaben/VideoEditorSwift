//
//  AVPlayer+isPlaying.swift
//  PryntTrimmerView
//
//  Created by Smart Mobile Tech on 28/11/18.
//

import AVFoundation

extension AVPlayer {

    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}
