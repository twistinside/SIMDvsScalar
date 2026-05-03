import Darwin
import Foundation

struct BenchmarkHardwareProfile: Sendable {
    let chipName: String
    let modelIdentifier: String
    let architecture: String
    let osVersion: String
    let wordBits: Int
    let pointerBits: Int
    let generalPurposeRegisterCount: Int?
    let generalPurposeRegisterBits: Int?
    let simdRegisterCount: Int?
    let simdRegisterBits: Int?
    let simdInstructionSet: String
    let physicalCPUCount: Int?
    let logicalCPUCount: Int?
    let memoryBytes: Int?
    let cacheLineBytes: Int?
    let l1DataCacheBytes: Int?
    let l1InstructionCacheBytes: Int?
    let l2CacheBytes: Int?
    let l3CacheBytes: Int?

    static let current = BenchmarkHardwareProfile(
        chipName: sysctlString("machdep.cpu.brand_string") ?? "Unknown CPU",
        modelIdentifier: sysctlString("hw.model") ?? "Unknown Mac",
        architecture: sysctlString("hw.machine") ?? "Unknown",
        osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
        wordBits: MemoryLayout<Int>.size * 8,
        pointerBits: MemoryLayout<UnsafeRawPointer>.size * 8,
        generalPurposeRegisterCount: registerProfile.generalPurposeRegisterCount,
        generalPurposeRegisterBits: registerProfile.generalPurposeRegisterBits,
        simdRegisterCount: registerProfile.simdRegisterCount,
        simdRegisterBits: registerProfile.simdRegisterBits,
        simdInstructionSet: registerProfile.simdInstructionSet,
        physicalCPUCount: sysctlInteger("hw.physicalcpu"),
        logicalCPUCount: sysctlInteger("hw.logicalcpu") ?? sysctlInteger("hw.ncpu"),
        memoryBytes: sysctlInteger("hw.memsize"),
        cacheLineBytes: sysctlInteger("hw.cachelinesize"),
        l1DataCacheBytes: sysctlInteger("hw.l1dcachesize"),
        l1InstructionCacheBytes: sysctlInteger("hw.l1icachesize"),
        l2CacheBytes: sysctlInteger("hw.l2cachesize"),
        l3CacheBytes: sysctlInteger("hw.l3cachesize")
    )

    static let csvHeader = [
        "chip_name",
        "model_identifier",
        "architecture",
        "os_version",
        "word_bits",
        "pointer_bits",
        "general_purpose_register_count",
        "general_purpose_register_bits",
        "simd_register_count",
        "simd_register_bits",
        "simd_instruction_set",
        "physical_cpu_count",
        "logical_cpu_count",
        "memory_bytes",
        "cache_line_bytes",
        "l1_data_cache_bytes",
        "l1_instruction_cache_bytes",
        "l2_cache_bytes",
        "l3_cache_bytes"
    ]

    var csvFields: [String] {
        [
            chipName,
            modelIdentifier,
            architecture,
            osVersion,
            "\(wordBits)",
            "\(pointerBits)",
            format(generalPurposeRegisterCount),
            format(generalPurposeRegisterBits),
            format(simdRegisterCount),
            format(simdRegisterBits),
            simdInstructionSet,
            format(physicalCPUCount),
            format(logicalCPUCount),
            format(memoryBytes),
            format(cacheLineBytes),
            format(l1DataCacheBytes),
            format(l1InstructionCacheBytes),
            format(l2CacheBytes),
            format(l3CacheBytes)
        ]
    }

    private static var registerProfile: RegisterProfile {
        #if arch(arm64)
        RegisterProfile(
            generalPurposeRegisterCount: 31,
            generalPurposeRegisterBits: 64,
            simdRegisterCount: 32,
            simdRegisterBits: 128,
            simdInstructionSet: "ARM ASIMD/NEON"
        )
        #elseif arch(x86_64)
        RegisterProfile(
            generalPurposeRegisterCount: 16,
            generalPurposeRegisterBits: 64,
            simdRegisterCount: 16,
            simdRegisterBits: x86SIMDRegisterBits,
            simdInstructionSet: x86SIMDInstructionSet
        )
        #else
        RegisterProfile(
            generalPurposeRegisterCount: nil,
            generalPurposeRegisterBits: nil,
            simdRegisterCount: nil,
            simdRegisterBits: nil,
            simdInstructionSet: "Unknown"
        )
        #endif
    }

    #if arch(x86_64)
    private static var x86SIMDRegisterBits: Int {
        if sysctlInteger("hw.optional.avx512f") == 1 {
            512
        } else if sysctlInteger("hw.optional.avx2_0") == 1 || sysctlInteger("hw.optional.avx1_0") == 1 {
            256
        } else {
            128
        }
    }

    private static var x86SIMDInstructionSet: String {
        if sysctlInteger("hw.optional.avx512f") == 1 {
            "AVX-512"
        } else if sysctlInteger("hw.optional.avx2_0") == 1 {
            "AVX2"
        } else if sysctlInteger("hw.optional.avx1_0") == 1 {
            "AVX"
        } else {
            "SSE"
        }
    }
    #endif

    private func format(_ value: Int?) -> String {
        value.map(String.init) ?? ""
    }

    private static func sysctlString(_ name: String) -> String? {
        guard var bytes = sysctlBytes(name), !bytes.isEmpty else {
            return nil
        }

        if bytes.last == 0 {
            bytes.removeLast()
        }

        return String(bytes: bytes, encoding: .utf8)
    }

    private static func sysctlInteger(_ name: String) -> Int? {
        guard let bytes = sysctlBytes(name), !bytes.isEmpty else {
            return nil
        }

        return bytes.withUnsafeBytes { buffer in
            switch bytes.count {
            case MemoryLayout<UInt32>.size:
                Int(buffer.loadUnaligned(as: UInt32.self))
            case MemoryLayout<UInt64>.size:
                Int(exactly: buffer.loadUnaligned(as: UInt64.self)) ?? Int.max
            default:
                nil
            }
        }
    }

    private static func sysctlBytes(_ name: String) -> [UInt8]? {
        var size = 0

        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else {
            return nil
        }

        var bytes = [UInt8](repeating: 0, count: size)
        let result = bytes.withUnsafeMutableBytes { buffer in
            sysctlbyname(name, buffer.baseAddress, &size, nil, 0)
        }

        guard result == 0 else {
            return nil
        }

        if size < bytes.count {
            bytes.removeLast(bytes.count - size)
        }

        return bytes
    }
}

private struct RegisterProfile {
    let generalPurposeRegisterCount: Int?
    let generalPurposeRegisterBits: Int?
    let simdRegisterCount: Int?
    let simdRegisterBits: Int?
    let simdInstructionSet: String
}
