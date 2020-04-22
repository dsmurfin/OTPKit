//
//  Folio.swift
//
//  Copyright (c) 2020 Daniel Murfin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/**
 Folio
  
 A folio stores a snapshot of transform information received across one or more messages from an `OTPProducer`.

*/

struct Folio {

    /// The `FolioNumber` which identifies this folio.
    var number: FolioNumber
    
    /// An array of page numbers which have been received for this folio.
    var pages: [Page]
    
    /// The last page number expected to be received for this folio.
    var lastPage: Page
    
    /// Whether this folio includes all `OTPPoint`s being transmitted for a particular `OTPProducer`.
    var fullPointSet: Bool
    
    /// An array of `ConsumerPoint`s which have been received from an `OTPProducer` with the same folio number.
    var points: [ConsumerPoint]
    
    /**
     Determines if this Folio is considered complete (has a full set of pages).
     
     - Returns: Whether this Folio has a full set of pages.
     
    */
    func isComplete() -> Bool {
        pages.count == lastPage + 1
    }
    
}

