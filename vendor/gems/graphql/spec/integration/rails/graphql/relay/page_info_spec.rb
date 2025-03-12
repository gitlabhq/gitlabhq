# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Relay::PageInfo" do
  def get_page_info(result)
    result["data"]["empire"]["bases"]["pageInfo"]
  end

  def get_first_cursor(result)
    result["data"]["empire"]["bases"]["edges"].first["cursor"]
  end

  def get_last_cursor(result)
    result["data"]["empire"]["bases"]["edges"].last["cursor"]
  end

  let(:cursor_of_last_base) {
    result = star_wars_query(query_string, { "first" => 100 })
    get_last_cursor(result)
  }

  let(:query_string) {%|
    query getShips($first: Int, $after: String, $last: Int, $before: String, $nameIncludes: String){
      empire {
        bases(first: $first, after: $after, last: $last, before: $before, nameIncludes: $nameIncludes) {
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          },
          edges {
            cursor
          }
        }
      }
    }
  |}

  describe 'hasNextPage / hasPreviousPage' do
    it "hasNextPage is true if there are more items" do
      result = star_wars_query(query_string, { "first" => 2 })
      assert_equal(true, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"], "hasPreviousPage is false if 'last' is missing")
      assert_equal("MQ", get_page_info(result)["startCursor"])
      assert_equal("Mg", get_page_info(result)["endCursor"])

      last_cursor = get_last_cursor(result)
      result = star_wars_query(query_string, { "first" => 100, "after" => last_cursor })
      assert_equal(false, get_page_info(result)["hasNextPage"])
      assert_equal(true, get_page_info(result)["hasPreviousPage"])
      assert_equal("Mw", get_page_info(result)["startCursor"])
      assert_equal("Mw", get_page_info(result)["endCursor"])
    end

    it "hasPreviousPage if there are more items" do
      result = star_wars_query(query_string, { "last" => 100, "before" => cursor_of_last_base })
      assert_equal(true, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ", get_page_info(result)["startCursor"])
      assert_equal("Mg", get_page_info(result)["endCursor"])

      result = star_wars_query(query_string, { "last" => 1, "before" => cursor_of_last_base })
      assert_equal(true, get_page_info(result)["hasNextPage"])
      assert_equal(true, get_page_info(result)["hasPreviousPage"])
      assert_equal("Mg", get_page_info(result)["startCursor"])
      assert_equal("Mg", get_page_info(result)["endCursor"])
    end

    it "has both if first and last are present" do
      result = star_wars_query(query_string, { "last" => 1, "first" => 1, "before" => cursor_of_last_base })
      assert_equal(true, get_page_info(result)["hasNextPage"])
      # I think this was actually a bug in the previous implementation.
      # This query returns the first node in the list:
      #     Base64.decode64("MQ") # => "1"
      # So, there is _not_ a previous page.
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ", get_page_info(result)["startCursor"])
      assert_equal("MQ", get_page_info(result)["endCursor"])
    end

    it "startCursor and endCursor are the cursors of the first and last edge" do
      result = star_wars_query(query_string, { "first" => 2 })
      assert_equal(true, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ", get_page_info(result)["startCursor"])
      assert_equal("Mg", get_page_info(result)["endCursor"])
      assert_equal("MQ", get_first_cursor(result))
      assert_equal("Mg", get_last_cursor(result))

      result = star_wars_query(query_string, { "first" => 1, "after" => get_page_info(result)["endCursor"] })
      assert_equal(false, get_page_info(result)["hasNextPage"])
      assert_equal(true, get_page_info(result)["hasPreviousPage"])
      assert_equal("Mw", get_page_info(result)["startCursor"])
      assert_equal("Mw", get_page_info(result)["endCursor"])
      assert_equal("Mw", get_first_cursor(result))
      assert_equal("Mw", get_last_cursor(result))

      result = star_wars_query(query_string, { "last" => 1, "before" => get_page_info(result)["endCursor"] })
      assert_equal(true, get_page_info(result)["hasNextPage"])
      assert_equal(true, get_page_info(result)["hasPreviousPage"])
      assert_equal("Mg", get_page_info(result)["startCursor"])
      assert_equal("Mg", get_page_info(result)["endCursor"])
      assert_equal("Mg", get_first_cursor(result))
      assert_equal("Mg", get_last_cursor(result))
    end
  end

  it "can be redefined" do
    conn_type = Class.new(GraphQL::Schema::Object) do
      include GraphQL::Types::Relay::ConnectionBehaviors

      get_field("pageInfo").type = GraphQL::Types::Int.to_non_null_type
    end

    assert_equal "Int!", conn_type.fields["pageInfo"].type.to_type_signature
    # The original is unchanged:
    assert_equal "PageInfo!", GraphQL::Types::Relay::BaseConnection.fields["pageInfo"].type.to_type_signature
  end
end
