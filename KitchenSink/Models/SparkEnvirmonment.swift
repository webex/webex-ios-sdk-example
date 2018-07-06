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
import SparkSDK


/// SparkSDK SetUp Inviroment Variables

/// saparkSDK reperesent for the SparkSDK API instance
var sparkSDK : Spark?
/// loggedInUser is for saving currently logged in Person info
var loggedInUser: Person?


///Get your own App Client information from https://developer.ciscospark.com
class SparkEnvirmonment {
    static let ClientId = "C416dd36dd57b536a35816978e4f063a98849d285ca191f5566a32c0f0c3481ab"
    static let ClientSecret = ProcessInfo().environment["CLIENTSECRET"] ?? "bc851e0f4d4bd62c020a45de08e374101910200d43096f32d14b9e08164adac7"
    ///Scopes define the level of access that your integration requires
    static let Scope = "spark:all"
    ///Uri is that a user will be redirected to when completing an OAuth grant flow
    static let RedirectUri = "KitchenSink://response"
}

