// Copyright 2016-2017 Cisco Systems Inc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import WebexSDK


public class UserDefaultsUtil {
    private static let CALL_PERSON_HISTORY_KEY = "KSCallPersonHistory"
    private static let CALL_MESSAGE_HISTORY_KEY = "KSMessagePersonHistory"
    private static let CALL_PERSON_HISTORY_ADDRESS_KEY = "KSCallPersonHistoryAddress"
    private static let CALL_VIDEO_ENABLE_KEY = "KSCallVideoEnable"
    private static let CALL_SELF_VIEW_ENABLE_KEY = "KSCallSelfViewEnable"
    static let userDefault = UserDefaults.standard
    static var userId : String?
    /// Call history person array.
    /// See addPersonHistory to add a call history.
    /// - note: if person's has no email address,discard it.
    static var callPersonHistory: [Person] {
        get {
            var resutlArray: [Person] = []
            if let selfId = UserDefaultsUtil.userId {
                let key = CALL_PERSON_HISTORY_KEY + selfId
                if let array = userDefault.array(forKey: key) {
                    for onePerson in array {
                        if let personString = onePerson as? String {
                            if let p = Person(JSONString: personString) {
                                if p.emails != nil {
                                    resutlArray.append(p)
                                }
                            }
                        }
                    }
                }
            }
            return resutlArray
            
        }
    }
    
    /// add a call history person into system user defaults
    /// - note: every log in user has there own call history array.
    static func addPersonHistory(_ person:Person) {
        let personString = person.toJSONString()
        
        guard personString != nil else {
            return
        }
        var resultArray: [Any] = Array.init()
        if let selfId = UserDefaultsUtil.userId {
            let key = CALL_PERSON_HISTORY_KEY + selfId
            if var array = userDefault.array(forKey: key) {
                for onePerson in array {
                    if let personString = onePerson as? String {
                        if let p = Person(JSONString: personString) {
                            if p.id == person.id {
                                return
                            }
                        }
                    }
                }
                array.append(personString!)
                if array.count > 10 {
                    array.removeFirst()
                }
                resultArray = array
            }
            else
            {
                resultArray.append(personString!)
            }
            userDefault.set(resultArray, forKey: key)
        }
    }
    /// Message history person array.
    /// See addMessagePersonHistory to add a message history.
    /// - note: if person's has no email address,discard it.
    static var meesagePersonHistory: [Person] {
        get {
            var resutlArray: [Person] = []
            if let selfId = UserDefaultsUtil.userId {
                let key = CALL_MESSAGE_HISTORY_KEY + selfId
                if let array = userDefault.array(forKey: key) {
                    for onePerson in array {
                        if let personString = onePerson as? String {
                            if let p = Person(JSONString: personString) {
                                if p.emails != nil {
                                    resutlArray.append(p)
                                }
                            }
                        }
                    }
                }
            }
            return resutlArray
            
        }
    }
    /// add a message history person into system user defaults
    /// - note: every log in user has there own call history array.
    static func addMessagePersonHistory(_ person:Person) {
        let personString = person.toJSONString()
        
        guard personString != nil else {
            return
        }
        var resultArray: [Any] = Array.init()
        if let selfId = UserDefaultsUtil.userId {
            let key = CALL_MESSAGE_HISTORY_KEY + selfId
            if var array = userDefault.array(forKey: key) {
                
                for onePerson in array {
                    if let personString = onePerson as? String {
                        if let p = Person(JSONString: personString) {
                            if p.id == person.id {
                                return
                            }
                        }
                    }
                }
                
                array.append(personString!)
                if array.count > 10 {
                    array.removeFirst()
                }
                resultArray = array
            }
            else
            {
                resultArray.append(personString!)
            }
            userDefault.set(resultArray, forKey: key)
        }
        
        
    }
}
