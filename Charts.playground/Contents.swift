import UIKit
import SwiftUI
import Charts
import PlaygroundSupport

struct AnimatingLine: View {
    var body: some View {
        chart
    }

    private var chart: some View {
        LineChart()
    }
}

func date(year: Int, month: Int, day: Int = 1) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}

struct MoodData: Identifiable, Equatable {
    let day: Date
    let mood: Double

    var id: Date { day }
}

struct LineChart: View {

    // Data for the previous week from Mon to Sun (1 - 7 Aug)
    static let previousWeekData: [MoodData] = stride(from: 1, through: 7, by: 1)
        .enumerated()
        .map { index, el in
            MoodData(
                day: date(year: 2022, month: 8, day: el),
                mood: Self.moods2[index]
            )
        }

    // Data for the current week from Mon to Sun (8 - 14 Aug)
    static let currentWeekData: [MoodData] = stride(from: 8, through: 14, by: 1)
        .enumerated()
        .map { index, el in
            MoodData(
                day: date(year: 2022, month: 8, day: el),
                mood: Self.moods1[index]
            )
        }

    static let moods1: [Double] = [2.5, 0.5, 1, 1.5, 2, 2.5, 3]
    static let moods2: [Double] = [2.5, 2, 2.5, 3.5, 2.5, 1.5, 3.0]

    enum Period: String, Equatable, Hashable, Plottable {
        case current
        case previous
    }

    struct Series: Identifiable {
        let period: Period
        let values: [(weekday: Date, sales: Double)]

        var id: Period { period }
    }

    static let data: [Series] = [
        Series(period: .current, values: Self.currentWeekData.map {
            ($0.day, $0.mood)
        }),
        Series(period: .previous, values: Self.previousWeekData.map {
            ($0.day, $0.mood)
        })
    ]

    static var dates: [Date] {
        Self.previousWeekData.map(\.day)
    }

    var body: some View {
        Chart(Self.data) { series in
            ForEach(series.values, id: \.weekday) { sample in
                LineMark(
                    x: .value("x", sample.weekday, unit: .weekday),
                    y: .value("y", sample.sales)
                )
                .foregroundStyle(by: .value("current", series.period))
                .lineStyle(.init(lineWidth: 6))
            }
            .interpolationMethod(.catmullRom)
        }
        .frame(width: 500, height: 400)
        .chartYScale(domain: -0.5 ... 4.5)
        .chartForegroundStyleScale([
            "current": .blue,
            "previous": .gray
        ])
        .chartLegend(position: .bottom, alignment: .center)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in // changing it to weekday throws `Charts/BinningUnit+Calendar.swift:317: Fatal error: component is not supported` error
                AxisGridLine()
                if value.index == 3 {
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                        .foregroundStyle(.red)
                } else {
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
        }
    }
}

public extension PlaygroundPage {
    func setUpScene() {
        let size: CGFloat = 600
        let vc = UIHostingController(
            rootView: AnimatingLine()
                .frame(width: size, height: size)
        )

        liveView = vc.view
        needsIndefiniteExecution = true
    }
}

PlaygroundPage.current.setUpScene()

extension Sequence {
    public func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, ascending: Bool = true) -> [Element] {
        if ascending {
            return sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
        } else {
            return sorted { $0[keyPath: keyPath] > $1[keyPath: keyPath] }
        }
    }
}
