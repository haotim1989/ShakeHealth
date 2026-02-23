import Foundation

enum DrinkCategory: String, Codable, CaseIterable, Identifiable {
    case milkTea = "奶茶類"
    case pureTea = "原茶類"
    case fruitTea = "果茶類"
    case coffee = "咖啡類"
    case fresh = "鮮奶系列"
    case special = "特調類"
    case custom = "自訂飲品"
    var id: String { rawValue }
}

struct Drink: Codable {
    let category: DrinkCategory
}

let json = """
{ "category": "fruitTea" }
"""

do {
    let data = json.data(using: .utf8)!
    let drink = try JSONDecoder().decode(Drink.self, from: data)
    print("Decoded: \(drink.category)")
} catch {
    print("Error: \(error)")
}
