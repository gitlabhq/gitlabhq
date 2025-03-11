# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::DefinitionSlice do
  let(:document) { GraphQL.parse(query_string) }

  describe "anonymous query with no dependencies" do
    let(:query_string) {%|
      {
        version
      }
    |}

    it "is already the smallest slice" do
      assert_equal document.to_query_string,
        document.slice_definition(nil).to_query_string
    end
  end

  describe "anonymous mutation with no dependencies" do
    let(:query_string) {%|
      mutation {
        ping {
          message
        }
      }
    |}

    it "is already the smallest slice" do
      assert_equal document.to_query_string,
        document.slice_definition(nil).to_query_string
    end
  end

  describe "anonymous fragment with no dependencies" do
    let(:query_string) {%|
      fragment on User {
        name
      }
    |}

    it "is already the smallest slice" do
      assert_equal document.to_query_string,
        document.slice_definition(nil).to_query_string
    end
  end

  describe "named query with no dependencies" do
    let(:query_string) {%|
      query getVersion {
        version
      }
    |}

    it "is already the smallest slice" do
      assert_equal document.to_query_string,
        document.slice_definition("getVersion").to_query_string
    end
  end

  describe "named fragment with no dependencies" do
    let(:query_string) {%|
      fragment profileFields on User {
        firstName
        lastName
      }
    |}

    it "is already the smallest slice" do
      assert_equal document.to_query_string,
        document.slice_definition("profileFields").to_query_string
    end
  end

  describe "document with multiple queries but no subdependencies" do
    let(:query_string) {%|
      query getVersion {
        version
      }

      query getTime {
        time
      }
    |}

    it "returns just the query definition" do
      assert_equal GraphQL::Language::Nodes::Document.new(definitions: [document.definitions[0]]).to_query_string,
        document.slice_definition("getVersion").to_query_string
      assert_equal GraphQL::Language::Nodes::Document.new(definitions: [document.definitions[1]]).to_query_string,
        document.slice_definition("getTime").to_query_string
    end
  end

  describe "document with multiple fragments but no subdependencies" do
    let(:query_string) {%|
      fragment profileFields on User {
        firstName
        lastName
      }

      fragment avatarFields on User {
        avatarURL(size: 80)
      }
    |}

    it "returns just the fragment definition" do
      assert_equal GraphQL::Language::Nodes::Document.new(definitions: [document.definitions[0]]).to_query_string,
        document.slice_definition("profileFields").to_query_string
      assert_equal GraphQL::Language::Nodes::Document.new(definitions: [document.definitions[1]]).to_query_string,
        document.slice_definition("avatarFields").to_query_string
    end
  end

  describe "query with missing spread" do
    let(:query_string) {%|
      query getUser {
        viewer {
          ...profileFields
        }
      }
    |}

    it "is ignored" do
      assert_equal document.to_query_string,
        document.slice_definition("getUser").to_query_string
    end
  end

  describe "query and fragment subdependency" do
    let(:query_string) {%|
      query getUser {
        viewer {
          ...profileFields
        }
      }

      fragment profileFields on User {
        firstName
        lastName
      }
    |}

    it "returns query and fragment dependency" do
      assert_equal document.to_query_string,
        document.slice_definition("getUser").to_query_string
    end
  end

  describe "query and fragment nested subdependencies" do
    let(:query_string) {%|
      query getUser {
        viewer {
          ...viewerInfo
        }
      }

      fragment viewerInfo on User {
        ...profileFields
      }

      fragment profileFields on User {
        firstName
        lastName
        ...avatarFields
      }

      fragment avatarFields on User {
        avatarURL(size: 80)
      }
    |}

    it "returns query and all fragment dependencies" do
      assert_equal document.to_query_string,
        document.slice_definition("getUser").to_query_string
    end
  end

  describe "fragment subdependency referenced multiple times" do
    let(:query_string) {%|
      query getUser {
        viewer {
          ...viewerInfo
          ...moreViewerInfo
        }
      }

      fragment viewerInfo on User {
        ...profileFields
      }

      fragment moreViewerInfo on User {
        ...profileFields
      }

      fragment profileFields on User {
        firstName
        lastName
      }
    |}

    it "is only returned once" do
      assert_equal document.to_query_string,
        document.slice_definition("getUser").to_query_string
    end
  end

  describe "query and unused fragment" do
    let(:query_string) {%|
      query getUser {
        viewer {
          id
        }
      }

      fragment profileFields on User {
        firstName
        lastName
      }
    |}

    it "returns just the query definition" do
      assert_equal GraphQL::Language::Nodes::Document.new(definitions: [document.definitions[0]]).to_query_string,
        document.slice_definition("getUser").to_query_string
    end
  end
end
