import Foundation
import Clibdivecomputer
import LibDCBridge
import SwiftUI

public enum DiveEvent: Hashable {
    case ascent
    case violation
    case decoStop
    case gasChange
    case bookmark
    case safetyStop(mandatory: Bool)
    case ceiling
    case po2
    case deepStop
    
    public var color: Color {
        switch self {
        case .ascent: return .red  // Warning color for ascent rate
        case .violation: return .red  // Warning color for violations
        case .decoStop: return .orange  // Important but not critical
        case .gasChange: return .blue  // Informational
        case .bookmark: return .yellow  // User marker
        case .safetyStop: return .green  // Good practice
        case .ceiling: return .red  // Warning color for ceiling violations
        case .po2: return .red  // Warning color for PPO2
        case .deepStop: return .purple  // Distinct from regular stops
        }
    }
    
    public var description: String {
        switch self {
        case .ascent: return "Ascent Rate Warning"
        case .violation: return "Violation"
        case .decoStop: return "Deco Stop Required"
        case .gasChange: return "Gas Mix Changed"
        case .bookmark: return "Bookmark"
        case .safetyStop(let mandatory): 
            return mandatory ? "Mandatory Safety Stop" : "Safety Stop"
        case .ceiling: return "Ceiling Violation"
        case .po2: return "PPO2 Warning"
        case .deepStop: return "Deep Stop"
        }
    }
    
    public var icon: String {
        switch self {
        case .ascent: return "exclamationmark.triangle"
        case .violation: return "exclamationmark.circle"
        case .decoStop: return "arrow.down.circle"
        case .gasChange: return "bubble.right"
        case .bookmark: return "bookmark"
        case .safetyStop: return "checkmark.circle"
        case .ceiling: return "arrow.up.circle"
        case .po2: return "aqi.high"
        case .deepStop: return "arrow.down.circle.fill"
        }
    }
}

public struct DiveProfilePoint {
    public let time: TimeInterval
    public let depth: Double
    public let temperature: Double?
    public let pressure: Double?
    public let po2: Double?  // Oxygen partial pressure
    public let pn2: Double?  // Nitrogen partial pressure
    public let phe: Double?  // Helium partial pressure
    public let events: [DiveEvent]
    
    public init(
        time: TimeInterval,
        depth: Double,
        temperature: Double? = nil,
        pressure: Double? = nil,
        po2: Double? = nil,
        pn2: Double? = nil,
        phe: Double? = nil,
        events: [DiveEvent] = []
    ) {
        self.time = time
        self.depth = depth
        self.temperature = temperature
        self.pressure = pressure
        self.po2 = po2
        self.pn2 = pn2
        self.phe = phe
        self.events = events
    }
}

public struct GasMix {
    public let helium: Double
    public let oxygen: Double
    public let nitrogen: Double
    public let usage: dc_usage_t
    
    public init(helium: Double, oxygen: Double, nitrogen: Double, usage: dc_usage_t) {
        self.helium = helium
        self.oxygen = oxygen
        self.nitrogen = nitrogen
        self.usage = usage
    }
}

public struct TankInfo {
    public let gasMix: Int  // Index to gas mix
    public let type: dc_tankvolume_t
    public let volume: Double
    public let workPressure: Double
    public let beginPressure: Double
    public let endPressure: Double
    public let usage: dc_usage_t
    
    public init(gasMix: Int, type: dc_tankvolume_t, volume: Double, workPressure: Double, 
               beginPressure: Double, endPressure: Double, usage: dc_usage_t) {
        self.gasMix = gasMix
        self.type = type
        self.volume = volume
        self.workPressure = workPressure
        self.beginPressure = beginPressure
        self.endPressure = endPressure
        self.usage = usage
    }
}

public struct DecoModel {
    public enum DecoType {
        case none
        case buhlmann
        case vpm
        case rgbm
        case dciem
        
        public var description: String {
            switch self {
            case .none: return "None"
            case .buhlmann: return "Bühlmann"
            case .vpm: return "VPM"
            case .rgbm: return "RGBM"
            case .dciem: return "DCIEM"
            }
        }
    }
    
    public let type: DecoType
    public let conservatism: Int
    public let gfLow: UInt32?
    public let gfHigh: UInt32?
    
    public var description: String {
        switch type {
        case .buhlmann:
            if let low = gfLow, let high = gfHigh {
                return "Bühlmann GF \(low)/\(high)"
            }
            return "Bühlmann"
        case .none:
            return "None"
        default:
            if conservatism != 0 {
                return "\(type.description) (\(conservatism))"
            } else {
                return type.description
            }
        }
    }
}

public struct Location {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    
    public init(latitude: Double, longitude: Double, altitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
}

public struct DiveData: Identifiable {
    public let id = UUID()
    public let number: Int
    public let datetime: Date
    
    // Basic dive data
    public var maxDepth: Double
    public var divetime: TimeInterval
    public var temperature: Double
    
    // Profile data
    public var profile: [DiveProfilePoint] 
    
    // Tank and gas data
    public var tankPressure: [Double]
    public var gasMix: Int?
    public var gasMixCount: Int?
    
    // Environmental data
    public var salinity: Double?
    public var atmospheric: Double?
    public var surfaceTemperature: Double?
    public var minTemperature: Double?
    public var maxTemperature: Double?
    
    // Tank information
    public var tankCount: Int?
    public var tanks: [Tank]?
    
    // Dive mode and model
    public var diveMode: DiveMode?
    public var decoModel: DecoModel?
    
    // Location data
    public var location: Location?
    
    // Additional sensor data
    public var rbt: UInt32?
    public var heartbeat: UInt32?
    public var bearing: UInt32?
    
    // Rebreather data
    public var setpoint: Double?
    public var ppo2Readings: [(sensor: UInt32, value: Double)]
    public var cns: Double?
    
    // Decompression data
    public var decoStop: DecoStop?
    
    public struct Tank {
        public var volume: Double
        public var workingPressure: Double
        public var beginPressure: Double
        public var endPressure: Double
        public var gasMix: Int
        public var usage: Usage
        
        public enum Usage {
            case none
            case oxygen
            case diluent
            case sidemount
        }
        
        public init(volume: Double, workingPressure: Double, beginPressure: Double, endPressure: Double, gasMix: Int, usage: Usage) {
            self.volume = volume
            self.workingPressure = workingPressure
            self.beginPressure = beginPressure
            self.endPressure = endPressure
            self.gasMix = gasMix
            self.usage = usage
        }
    }
    
    public struct DecoStop {
        public var depth: Double
        public var time: TimeInterval
        public var type: Int
        
        public init(depth: Double, time: TimeInterval, type: Int) {
            self.depth = depth
            self.time = time
            self.type = type
        }
    }
    
    public struct Location {
        public var latitude: Double
        public var longitude: Double
        public var altitude: Double?
        
        public init(latitude: Double, longitude: Double, altitude: Double? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.altitude = altitude
        }
    }
    
    public enum DiveMode {
        case freedive
        case gauge
        case openCircuit
        case closedCircuit
        case semiClosedCircuit
        
        public var description: String {
            switch self {
            case .freedive: return "Freedive"
            case .gauge: return "Gauge"
            case .openCircuit: return "Open Circuit"
            case .closedCircuit: return "Closed Circuit"
            case .semiClosedCircuit: return "Semi-Closed Circuit"
            }
        }
    }
    
    public struct DecoModel {
        public var type: DecoType
        public var conservatism: Int
        public var gfLow: UInt32?
        public var gfHigh: UInt32?
        
        public enum DecoType {
            case none
            case buhlmann
            case vpm
            case rgbm
            case dciem
            
            public var description: String {
                switch self {
                case .none: return "None"
                case .buhlmann: return "Bühlmann"
                case .vpm: return "VPM"
                case .rgbm: return "RGBM"
                case .dciem: return "DCIEM"
                }
            }
        }
        
        public init(type: DecoType, conservatism: Int, gfLow: UInt32? = nil, gfHigh: UInt32? = nil) {
            self.type = type
            self.conservatism = conservatism
            self.gfLow = gfLow
            self.gfHigh = gfHigh
        }
        
        public var description: String {
            switch type {
            case .buhlmann:
                if let low = gfLow, let high = gfHigh {
                    return "Bühlmann GF \(low)/\(high)"
                }
                return "Bühlmann"
            case .none:
                return "None"
            default:
                if conservatism != 0 {
                    return "\(type.description) (\(conservatism))"
                } else {
                    return type.description
                }
            }
        }
    }
    
    public init(
        number: Int,
        datetime: Date,
        maxDepth: Double,
        divetime: TimeInterval,
        temperature: Double,
        profile: [DiveProfilePoint],
        tankPressure: [Double],
        gasMix: Int?,
        gasMixCount: Int?,
        salinity: Double?,
        atmospheric: Double?,
        surfaceTemperature: Double?,
        minTemperature: Double?,
        maxTemperature: Double?,
        tankCount: Int?,
        tanks: [Tank]?,
        diveMode: DiveMode?,
        decoModel: DecoModel?,
        location: Location?,
        rbt: UInt32?,
        heartbeat: UInt32?,
        bearing: UInt32?,
        setpoint: Double?,
        ppo2Readings: [(sensor: UInt32, value: Double)],
        cns: Double?,
        decoStop: DecoStop?
    ) {
        self.number = number
        self.datetime = datetime
        self.maxDepth = maxDepth
        self.divetime = divetime
        self.temperature = temperature
        self.profile = profile
        self.tankPressure = tankPressure
        self.gasMix = gasMix
        self.gasMixCount = gasMixCount
        self.salinity = salinity
        self.atmospheric = atmospheric
        self.surfaceTemperature = surfaceTemperature
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
        self.tankCount = tankCount
        self.tanks = tanks
        self.diveMode = diveMode
        self.decoModel = decoModel
        self.location = location
        self.rbt = rbt
        self.heartbeat = heartbeat
        self.bearing = bearing
        self.setpoint = setpoint
        self.ppo2Readings = ppo2Readings
        self.cns = cns
        self.decoStop = decoStop
    }
} 
