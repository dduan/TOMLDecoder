import XCTest

extension TOMLDecoderTests {
    static let __allTests = [
        ("testBasicGeneratedCodables", testBasicGeneratedCodables),
        ("testDecodingContainerKeyed", testDecodingContainerKeyed),
        ("testDecodingCustomKeyStrategy", testDecodingCustomKeyStrategy),
        ("testDecodingFoundationDataWithBase64", testDecodingFoundationDataWithBase64),
        ("testDecodingFoundationDataWithCustom", testDecodingFoundationDataWithCustom),
        ("testDecodingSnakeCaseKeyStrategy", testDecodingSnakeCaseKeyStrategy),
        ("testFoundationDateComponentsFromLocalDateDecoding", testFoundationDateComponentsFromLocalDateDecoding),
        ("testFoundationDateComponentsFromLocalDateTimeDecoding", testFoundationDateComponentsFromLocalDateTimeDecoding),
        ("testFoundationDateComponentsFromLocalTimeDecoding", testFoundationDateComponentsFromLocalTimeDecoding),
        ("testFoundationDateDecoding", testFoundationDateDecoding),
        ("testFoundationDateDecodingWithStrictStrategy", testFoundationDateDecodingWithStrictStrategy),
        ("testLenientIntegerDecodingStrategy", testLenientIntegerDecodingStrategy),
        ("testNestedUnkeyedDecodingContainer", testNestedUnkeyedDecodingContainer),
        ("testNetTimeDateDecoding", testNetTimeDateDecoding),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TOMLDecoderTests.__allTests),
    ]
}
#endif
