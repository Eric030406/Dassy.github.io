//
//  EconomicCalendarView.swift
//
//  Created by Ji hyuk Song on 22/11/20.
//

import SwiftUI
import SwiftSoup

enum Country: String {
    case USA = "https://mql5.com/ko/economic-calendar/united-states"
    case Korea = "https://mql5.com/ko/economic-calendar/south-korea"
    case Europe = "https://mql5.com/ko/economic-calendar/european-union"
    case Japan = "https://mql5.com/ko/economic-calendar/japan"
    case China = "https://mql5.com/ko/economic-calendar/china"
    case Germany = "https://mql5.com/ko/economic-calendar/germany"
    case England = "https://mql5.com/ko/economic-calendar/united-kingdom"
}

struct EconomicCalendarView: View {
    @State private var isClicked = false
    @State private var date = Date()
    @State private var country: Country = .USA
    @EnvironmentObject var scraping: Scraping
    @EnvironmentObject var economicCalendarViewModel: EconomicCalendarViewModel
    
    func dateToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter.string(from: self.date)
    }
    
    var body: some View {
            VStack {
                Picker("Country", selection: $country) {
                    Text("Korea").tag(Country.Korea)
                    Text("USA").tag(Country.USA)
                    Text("Europe").tag(Country.Europe)
                    Text("England").tag(Country.England)
                    Text("Japan").tag(Country.Japan)
                    Text("Germany").tag(Country.Germany)
                    Text("China").tag(Country.China)
                }
                .pickerStyle(.wheel)
                .padding()
                .onChange(of: country, perform: { value in
                    switch value {
                    case .USA:
                        scraping.fetchURL(country: .USA)
                    case .Korea:
                        scraping.fetchURL(country: .Korea)
                    case .Europe:
                        scraping.fetchURL(country: .Europe)
                    case .England:
                        scraping.fetchURL(country: .England)
                    case .Germany:
                        scraping.fetchURL(country: .Germany)
                    case .Japan:
                        scraping.fetchURL(country: .Japan)
                    case .China:
                        scraping.fetchURL(country: .China)
                    }})
                    Lisst()                    
                }
                

            }
}

class Scraping: ObservableObject {
    @Published var arr: [String] = []
    
    func fetchURL(country: Country) {
        
        guard let url = URL(string: country.rawValue) else { return }
        if let html = try? String(contentsOf: url, encoding: .utf8) {
            do {
                    let datePattern: String = "(?<year>[0-9]{4})[.](?<month>[0-9]{2})[.](?<date>[0-9]{2})"
                    let regex = try? NSRegularExpression(pattern: datePattern, options: [])
                    var remove = false
                    var count = 0
                    let doc: Document = try SwiftSoup.parse(html)
                    let calendar3: Elements = try doc.select("div.ec-table__item").select("div")
                    let event = try calendar3.text()
                    var arr2 = event.components(separatedBy: ", ")
                    
                    for var index in 0..<arr2.count {
                        if remove {
                            remove = false
                        } 
                        index-=count
                        if index >= arr2.startIndex && index < arr2.endIndex {
                            if arr2[index].contains("??????:") || arr2[index].contains("USD") || arr2[index].contains("KRW") || arr2[index].contains("EUR") || arr2[index].contains("GBP") || arr2[index].contains("JPY") || arr2[index].contains("CNY") || arr2[index].contains("??????:") {
                                arr2.remove(at: index)
                                remove = true
                                count+=1
                            }
                        }
                        
                        if let result = regex?.matches(in: arr2[index], options: [], range: NSRange(location: 0, length: arr2[index].count)) {
                            let rexStrings = result.compactMap { (element) -> String in
                                let yearRange = Range(element.range(withName: "year"), in: arr2[index])!
                                let monthRange = Range(element.range(withName: "month"), in: arr2[index])!
                                let dateRange = Range(element.range(withName: "date"), in: arr2[index])!
                                
                                return "\(arr2[index][yearRange]).\(arr2[index][monthRange]).\(arr2[index][dateRange])"
                            } 
                            if !rexStrings.isEmpty && arr2[index].contains("??????:") {
                                arr2[index] = rexStrings[0]
                            } else if !rexStrings.isEmpty && arr2[index].count >= 17 {
                                let w = arr2[index].index(arr2[index].endIndex, offsetBy: -16)
                                let h = arr2[index].index(arr2[index].endIndex, offsetBy: -17)
                                let t = arr2[index].index(arr2[index].endIndex, offsetBy: -6)
                                let name = String(arr2[index][...h])
                                let time = String(arr2[index][w...t])
                                arr2.insert(time, at: index+1)
                                arr2[index] = name
                                
                            }
                        }
                    }
                    self.arr = arr2
                    
                }
                catch let error {
                    print(error)
                }
        }
    }
}

struct Lisst: View {
    @EnvironmentObject var scraping: Scraping
    
    func date(day: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY.MM.dd"
        return dateFormatter.string(from: Date(timeInterval: day*86400, since: Date()))
    }
    
    func week() -> [String] {
        var week: [String] = []        
        week.append(date(day: 0))
        week.append(date(day: 1))
        week.append(date(day: 2))
        week.append(date(day: 3))
        week.append(date(day: 4))
        week.append(date(day: 5))
        week.append(date(day: 6))
        
        return week
    }
    
    var body: some View {
        
        List(0..<6, id: \.self) { index in
                Section(header: Text(week()[index])) {
                    ForEach(0..<scraping.arr.count , id: \.self) { index2 in
                        if scraping.arr[index2] == week()[index] {
                            Text(scraping.arr[index2+1])
                        }
                    }
            }
        }
        .id(UUID())
        .listStyle(SidebarListStyle())
        .padding(8)
    }
}


