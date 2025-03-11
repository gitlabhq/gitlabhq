import { removeClientFieldsFromString } from "../removeClientFields"


describe("removing @client fields", () => {
  function normalizeString(str: string) {
    return str.replace(/\s+/g, " ").trim()
  }

  it("returns a string without any fields with @client", () => {
    var newString = removeClientFieldsFromString("{ f1 f2 @client { a b } f3 { a b @client } }")
    var expectedString = "{ f1 f3 { a } }"
    expect(normalizeString(newString)).toEqual(expectedString)
  })

  it("leaves other strings unchanged", () => {
    var originalString = "{ f1 f2 @other { a b } f3 { a b @notClient } }"
    var newString = removeClientFieldsFromString(originalString)
    expect(normalizeString(newString)).toEqual(originalString)
  })

  it("removes references to fragments that contain all client fields", () => {
    var originalString = `
    {
      f1
      ...Fragment1
      ... on Query {
        f3
        ...Fragment2
      }
      ...Fragment3
    }

    fragment Fragment1 on Query {
      f2 @client
      f3
      ...Fragment2
    }

    fragment Fragment2 on Query {
      f4 @client
      f5 @client
      f6 @client {
        f7
        f8
      }
    }

    fragment Fragment3 on Query {
      ...Fragment2
    }
    `

    var expectedString = `
    {
      f1
      ...Fragment1
      ... on Query {
        f3
      }
    }

    fragment Fragment1 on Query {
      f3
    }
    `

    var newString = removeClientFieldsFromString(originalString)
    expect(normalizeString(newString)).toEqual(normalizeString(expectedString))
  })

  it("removes now-unused variables", () => {
    var newString = removeClientFieldsFromString("query($thing: ID!){ f1 f2(thing: $thing) @client }")
    var expectedString = "{ f1 }"
    expect(normalizeString(newString)).toEqual(expectedString)
  })

  it("removes fragments that are spread inside client fields", () => {
    // from https://github.com/apollographql/apollo-client/pull/6892/
    var originalString = `
    query Simple {
      networkField
      field @client {
        ...ClientFragment
      }
    }
    fragment ClientFragment on Thing {
      ...NestedFragment
    }
    fragment NestedFragment on Thing {
      otherField
      bar
    }`
    var expectedString = `
    query Simple {
      networkField
    }
    `

    var newString = removeClientFieldsFromString(originalString)
    expect(normalizeString(newString)).toEqual(normalizeString(expectedString))
  })
})
