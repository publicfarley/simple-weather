import Foundation

extension Measurement where UnitType == UnitTemperature {
    func roundedUp() -> Measurement<UnitTemperature> {
        let roundedValue = ceil(self.value)
        return Measurement(value: roundedValue, unit: self.unit)
    }
}
