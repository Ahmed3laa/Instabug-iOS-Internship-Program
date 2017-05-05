import UIKit
import XCTest

//Added for error handling
enum JsonStringError: Error {
    case UnmatchedCase(String)
    case UnmatchedState(String)
    case UnmatchedTimeStamp(String)
    case UnmatchedComment(String)
}
// My object of date is between two dates
extension Date {
    
    func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.timeIntervalSinceReferenceDate > self.timeIntervalSinceReferenceDate && date2.timeIntervalSinceReferenceDate < self.timeIntervalSinceReferenceDate
    }
    
}
class Bug {
    enum State {
        case open
        case closed
    }
    
    let state: State
    let timestamp: Date
    let comment: String
    
    init(state: State, timestamp: Date, comment: String) {
        // implemented
        self.state=state
        self.timestamp=timestamp
        self.comment=comment
    }
    
    init(jsonString: String) throws {
        //implemented
      let jsString = jsonString.components(separatedBy: ",")
      var cstate :State = .open
      var ctimestampe:Date=Date()
      var ccomment:String=""
      if jsString.count != 3
      {
        throw JsonStringError.UnmatchedCase("Un matched case for Json String")
      }
      for initializer in jsString
        {

            if initializer.range(of:"\"state\":") != nil
            {
                if initializer.range(of:"open") != nil
                { cstate = .open }
                else if initializer.range(of:"closed") != nil
                { cstate = .closed }
                else {throw JsonStringError.UnmatchedTimeStamp("Un matched state in Json String")}
            }
            else if initializer.range(of:"\"timestamp\":") != nil
            {
                let subInit = initializer.replacingOccurrences(
                    of: "[^\\d+]", with: "", options: NSString.CompareOptions.regularExpression,
                    range: initializer.startIndex..<initializer.endIndex)
                if subInit == ""
                { throw JsonStringError.UnmatchedTimeStamp("Un matched Time Stamp in Json String") }
                let date = Date(timeIntervalSince1970: Double(subInit)!)
                ctimestampe=date
            }
                
            else if initializer.range(of:"\"comment\":") != nil
            {
                let jsSubString = initializer.components(separatedBy: "\"")
                if(jsSubString.count > 2)
                {
                    ccomment = jsSubString[3]
                }
                else
                {
                    throw JsonStringError.UnmatchedCase("Un matched comment in Json String")

                }
            }
            else { throw JsonStringError.UnmatchedCase("Un matched case for Json String") }
        }
        self.state=cstate
        self.comment=ccomment
        self.timestamp=ctimestampe
    }
}

enum TimeRange {
    case pastDay
    case pastWeek
    case pastMonth
}

class Application {
    var bugs: [Bug]
    
    init(bugs: [Bug]) {
        self.bugs = bugs
    }
    
    func findBugs(state: Bug.State?, timeRange: TimeRange) -> [Bug] {
        //implemented
        var tempbugs : [Bug]=[]
        for bug in self.bugs
        {
            if state != nil
            {
                if bug.state == state
                {
                    switch(timeRange)
                    {
                    case .pastDay:
                        var date24hoursAgo = Date()
                        date24hoursAgo.addTimeInterval(-1 * (24 * 60 * 60))
                        if bug.timestamp.isBetweeen(date: Date(),andDate: date24hoursAgo)
                        {tempbugs.append(bug)}
                        
                    case .pastWeek:
                        var date1WeekAgo = Date()
                        date1WeekAgo.addTimeInterval(-1 * (7 * 24 * 60 * 60))
                        if bug.timestamp.isBetweeen(date: Date(),andDate: date1WeekAgo)
                        {tempbugs.append(bug)}

                    case .pastMonth:
                        var date1MonthAgo = Date()
                        date1MonthAgo.addTimeInterval(-1 * (30 * 24 * 60 * 60))
                        if bug.timestamp.isBetweeen(date: Date(),andDate: date1MonthAgo)
                        {tempbugs.append(bug)}
                    }
                }
            }
        }
        return tempbugs
    }
}

class UnitTests : XCTestCase {
    lazy var bugs: [Bug] = {
        var date26HoursAgo = Date()
        date26HoursAgo.addTimeInterval(-1 * (26 * 60 * 60))
        
        var date2WeeksAgo = Date()
        date2WeeksAgo.addTimeInterval(-1 * (14 * 24 * 60 * 60))
        
        let bug1 = Bug(state: .open, timestamp: Date(), comment: "Bug 1")
        let bug2 = Bug(state: .open, timestamp: date26HoursAgo, comment: "Bug 2")
        let bug3 = Bug(state: .closed, timestamp: date2WeeksAgo, comment: "Bug 2")

        return [bug1, bug2, bug3]
    }()
    
    lazy var application: Application = {
        let application = Application(bugs: self.bugs)
        return application
    }()

    func testFindOpenBugsInThePastDay() {
        let bugs = application.findBugs(state: .open, timeRange: .pastDay)
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
        XCTAssertEqual(bugs[0].comment, "Bug 1", "Invalid bug order")
    }
    
    func testFindClosedBugsInThePastMonth() {
        let bugs = application.findBugs(state: .closed, timeRange: .pastMonth)
        XCTAssertTrue(bugs.count == 1, "Invalid number of bugs")
    }
    
    func testFindClosedBugsInThePastWeek() {
        let bugs = application.findBugs(state: .closed, timeRange: .pastWeek)
        
        XCTAssertTrue(bugs.count == 0, "Invalid number of bugs")
    }
    
    func testInitializeBugWithJSON() {
        do {
            let json = "{\"state\": \"open\",\"timestamp\": 1493393946,\"comment\": \"Bug via JSON\"}"

            let bug = try Bug(jsonString: json)
            
            XCTAssertEqual(bug.comment, "Bug via JSON")
            XCTAssertEqual(bug.state, .open)
            XCTAssertEqual(bug.timestamp, Date(timeIntervalSince1970: 1493393946))
        } catch {
            print(error)
        }
    }
}

class PlaygroundTestObserver : NSObject, XCTestObservation {
    @objc func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: UInt) {
        print("Test failed on line \(lineNumber): \(String(describing: testCase.name)), \(description)")
    }
}

let observer = PlaygroundTestObserver()
let center = XCTestObservationCenter.shared()
center.addTestObserver(observer)

TestRunner().runTests(testClass: UnitTests.self)
