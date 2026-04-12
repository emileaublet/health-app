import Foundation

extension Double {
    func rounded(to places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }

    var hoursMinutesString: String {
        let h = Int(self)
        let m = Int((self - Double(h)) * 60)
        return "\(h)h\(String(format: "%02d", m))"
    }

    var oneDecimal: String {
        String(format: "%.1f", self)
    }

    var noDecimal: String {
        String(format: "%.0f", self)
    }

    var twoDecimals: String {
        String(format: "%.2f", self)
    }

    /// Affichage selon le type de métrique
    func formatted(for dataType: MetricDataType) -> String {
        switch dataType {
        case .counter: return noDecimal
        case .boolean: return self == 1 ? "Oui" : "Non"
        case .scale:   return noDecimal
        }
    }
}

extension Optional where Wrapped == Double {
    var displayString: String {
        guard let v = self else { return "—" }
        return String(format: "%.1f", v)
    }
}
