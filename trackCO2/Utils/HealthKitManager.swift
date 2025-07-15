import Foundation
import HealthKit

@Observable
class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    var todaySteps: Double = 0
    var todayDistance: Double = 0 // in meters
    var stepsHistory: [Double] = [] // last 7 days
    var distanceHistory: [Double] = [] // last 7 days
    var stepsPerHour: [Double] = Array(repeating: 0, count: 24) // steps for each hour of today
    var distancePerHour: [Double] = Array(repeating: 0, count: 24) // distance (meters) for each hour of today
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let typesToRead: Set = [stepType, distanceType]
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func fetchTodayData() {
        fetchSteps(for: Date()) { steps in
            DispatchQueue.main.async {
                self.todaySteps = steps
            }
        }
        fetchDistance(for: Date()) { distance in
            DispatchQueue.main.async {
                self.todayDistance = distance
            }
        }
    }
    
    func fetchHistoryData(days: Int = 7) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var stepsArr: [Double] = []
        var distanceArr: [Double] = []
        let group = DispatchGroup()
        
        for i in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                group.enter()
                fetchSteps(for: date) { steps in
                    stepsArr.append(steps)
                    group.leave()
                }
                group.enter()
                fetchDistance(for: date) { distance in
                    distanceArr.append(distance)
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            self.stepsHistory = stepsArr
            self.distanceHistory = distanceArr
        }
    }
    
    private func fetchSteps(for date: Date, completion: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            completion(0)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            completion(steps)
        }
        healthStore.execute(query)
    }
    
    private func fetchDistance(for date: Date, completion: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            completion(0)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
            completion(distance)
        }
        healthStore.execute(query)
    }

    // Fetch steps per hour for today
    func fetchStepsPerHourForToday(completion: (() -> Void)? = nil) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        var hourSteps = Array(repeating: 0.0, count: 24)
        let group = DispatchGroup()
        for hour in 0..<24 {
            group.enter()
            let start = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
            let end = calendar.date(byAdding: .hour, value: 1, to: start)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                hourSteps[hour] = steps
                group.leave()
            }
            healthStore.execute(query)
        }
        group.notify(queue: .main) {
            self.stepsPerHour = hourSteps
            completion?()
        }
    }

    // Fetch total steps for today
    func fetchTodaySteps(completion: (() -> Void)? = nil) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                self.todaySteps = steps
                completion?()
            }
        }
        healthStore.execute(query)
    }

    // Fetch walking/running distance per hour for today
    func fetchDistancePerHourForToday(completion: (() -> Void)? = nil) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        var hourDistances = Array(repeating: 0.0, count: 24)
        let group = DispatchGroup()
        for hour in 0..<24 {
            group.enter()
            let start = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
            let end = calendar.date(byAdding: .hour, value: 1, to: start)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                hourDistances[hour] = distance
                group.leave()
            }
            healthStore.execute(query)
        }
        group.notify(queue: .main) {
            self.distancePerHour = hourDistances
            completion?()
        }
    }

    // Fetch total walking/running distance for yesterday
    func fetchYesterdayDistance(completion: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            completion(0)
            return
        }
        let start = yesterday
        let end = today
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
            DispatchQueue.main.async {
                completion(distance)
            }
        }
        healthStore.execute(query)
    }
} 
