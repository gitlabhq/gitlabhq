import {addTypenameToSelectionSet} from "../addTypenameToSelectionSet"
import { parse, print } from "graphql"

describe("adding typename", () => {
  it("adds to fields and inline fragments", () => {
    var doc = parse("{ a { b ... { c } } }")
    var newDoc = addTypenameToSelectionSet(doc)
    var newString = print(newDoc).replace(/\s+/g, " ").trim()
    expect(newString).toEqual("{ a { b ... { c __typename } __typename } }")
  })
})
