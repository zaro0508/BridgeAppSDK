//
//  SBAUserProfileController.swift
//  BridgeAppSDK
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

/**
 Protocols for sharing functionality between different classes that do not share inheritance.
 This set of protocols are used to handle account access.
 */
public protocol SBAUserProfileController: class, SBAAccountController, SBAResearchKitResultConverter, SBANameDataSource {
}

extension SBAUserProfileController {
    
    func updateUserProfileInfo() {

        if let name = self.name {
            self.sharedUser.name = name
        }
        if let familyName = self.familyName {
            self.sharedUser.familyName = familyName
        }
        if let gender = self.gender {
            self.sharedUser.gender = gender
        }
        if let birthdate = self.birthdate {
            self.sharedUser.birthdate = birthdate
        }
        else if (self.birthdate == nil), let currentAge = self.currentAge {
            self.sharedUser.birthdate = Date(currentAge: currentAge)
        }
    }
    
    func updateConsentSignature() {
        guard let signature = sharedUser.consentSignature else { return }
        
        if let fullName = self.fullName ?? self.sharedNameDataSource?.fullName {
            signature.signatureName = fullName
        }
        if let birthdate = self.birthdate ?? sharedUser.birthdate {
            signature.signatureBirthdate = birthdate
        }
    }
}

/**
 The `SBAAccountController`can be attached to an `ORKStepViewController` that implements account management
 functionality and uses a shared method for alerting the user when there is a problem.
 */
public protocol SBAAccountController: class, SBASharedInfoController, SBAAlertPresenter, SBALoadingViewPresenter {
    var failedValidationMessage: String { get }
    var failedRegistrationTitle: String { get }
}

extension SBAAccountController {
    
    /**
     Handle failed account validation by displaying a message string.
    */
    func handleFailedValidation(_ reason: String? = nil) {
        let message = reason ?? failedValidationMessage
        self.hideLoadingView({ [weak self] in
            self?.showAlertWithOk(title: self?.failedRegistrationTitle, message: message, actionHandler: nil)
        })
    }
    
    /**
     Handle a failed registration or login step by displaying the bridge error message.
    */
    func handleFailedRegistration(_ error: Error) {
        let message = (error as NSError).localizedBridgeErrorMessage
        handleFailedValidation(message)
    }
}
