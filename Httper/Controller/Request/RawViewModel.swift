//
//  RawViewModel.swift
//  Httper
//
//  Created by Meng Li on 2018/10/05.
//  Copyright © 2018 MuShare. All rights reserved.
//

import RxSwift
import RxFlow

class RawViewModel {
    
    let text = PublishSubject<String>()
    
    func set(text: String) {
        self.text.onNext(text)
    }
    
}

extension RawViewModel: Stepper {
    
}
