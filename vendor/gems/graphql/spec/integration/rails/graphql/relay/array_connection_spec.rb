# frozen_string_literal: true
require 'spec_helper'

describe "GraphQL::Relay::ArrayConnection" do
  def get_names(result)
    ships = result["data"]["rebels"]["ships"]["edges"]
    ships.map { |e| e["node"]["name"] }
  end

  def get_last_cursor(result)
    result["data"]["rebels"]["ships"]["edges"].last["cursor"]
  end

  def get_page_info(result, key = "bases")
    result["data"]["rebels"][key]["pageInfo"]
  end

  describe "results" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String, $nameIncludes: String){
        rebels {
          ships(first: $first, after: $after, last: $last, before: $before, nameIncludes: $nameIncludes) {
            edges {
              cursor
              node {
                name
              }
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
          }
        }
      }
    |}

    it 'limits the result' do
      result = star_wars_query(query_string, { "first" => 2 })
      number_of_ships = get_names(result).length
      assert_equal(2, number_of_ships)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasPreviousPage"])
      assert_equal("MQ", result["data"]["rebels"]["ships"]["pageInfo"]["startCursor"])
      assert_equal("Mg", result["data"]["rebels"]["ships"]["pageInfo"]["endCursor"])

      result = star_wars_query(query_string, { "first" => 3 })
      number_of_ships = get_names(result).length
      assert_equal(3, number_of_ships)
    end

    it 'provides pageInfo' do
      result = star_wars_query(query_string, { "first" => 2 })
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasPreviousPage"])
      assert_equal("MQ", result["data"]["rebels"]["ships"]["pageInfo"]["startCursor"])
      assert_equal("Mg", result["data"]["rebels"]["ships"]["pageInfo"]["endCursor"])

      result = star_wars_query(query_string, { "first" => 100 })
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasPreviousPage"])
      assert_equal("MQ", result["data"]["rebels"]["ships"]["pageInfo"]["startCursor"])
      assert_equal("NQ", result["data"]["rebels"]["ships"]["pageInfo"]["endCursor"])
    end



    it 'slices the result' do
      result = star_wars_query(query_string, { "first" => 1 })
      assert_equal(["X-Wing"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, { "after" => last_cursor, "first" => 2 })
      assert_equal(["Y-Wing", "A-Wing"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, { "after" => last_cursor, "first" => 2 })
      assert_equal(["Millennium Falcon", "Home One"], get_names(result))

      result = star_wars_query(query_string, { "before" => last_cursor, "last" => 2 })
      assert_equal(["X-Wing", "Y-Wing"], get_names(result))

      result = star_wars_query(query_string, { "last" => 2 })
      assert_equal(["Millennium Falcon", "Home One"], get_names(result))

      result = star_wars_query(query_string, { "last" => 10 })
      assert_equal(["X-Wing", "Y-Wing", "A-Wing", "Millennium Falcon", "Home One"], get_names(result))
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasPreviousPage"])
    end

    it 'works with before and after specified together' do
      result = star_wars_query(query_string, { "first" => 1 })
      assert_equal(["X-Wing"], get_names(result))

      first_cursor = get_last_cursor(result)

      # There is no records between before and after if they point to the same cursor
      result = star_wars_query(query_string, { "before" => first_cursor, "after" => first_cursor, "last" => 2 })
      assert_equal([], get_names(result))

      result = star_wars_query(query_string, { "after" => first_cursor, "first" => 2 })
      assert_equal(["Y-Wing", "A-Wing"], get_names(result))

      third_cursor = get_last_cursor(result)

      # There is only 1 result between the cursors
      result = star_wars_query(query_string, { "after" => first_cursor, "before" => third_cursor, "first" => 5 })
      assert_equal(["Y-Wing"], get_names(result))
    end

    it 'handles cursors beyond the bounds of the array' do
      overreaching_cursor = Base64.strict_encode64("100")
      result = star_wars_query(query_string, { "after" => overreaching_cursor, "first" => 2 })
      assert_equal([], get_names(result))
    end

    it 'applies custom arguments' do
      result = star_wars_query(query_string, { "nameIncludes" => "Wing", "first" => 2 })
      names = get_names(result)
      assert_equal(2, names.length)

      after = get_last_cursor(result)
      result = star_wars_query(query_string, { "nameIncludes" => "Wing", "after" => after, "first" => 3 })
      names = get_names(result)
      assert_equal(1, names.length)
    end

    it 'works without first/last/after/before' do
      result = star_wars_query(query_string)

      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasPreviousPage"])
      assert_equal("MQ", result["data"]["rebels"]["ships"]["pageInfo"]["startCursor"])
      assert_equal("NQ", result["data"]["rebels"]["ships"]["pageInfo"]["endCursor"])
      assert_equal(5, result["data"]["rebels"]["ships"]["edges"].length)
    end

    describe "applying max_page_size" do
      def get_names(result)
        result["data"]["rebels"]["bases"]["edges"].map { |e| e["node"]["name"] }
      end

      let(:query_string) {%|
        query getShips($first: Int, $after: String, $last: Int, $before: String){
          rebels {
            bases: basesWithMaxLimitArray(first: $first, after: $after, last: $last, before: $before) {
              edges {
                cursor
                node {
                  name
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
            }
          }
        }
      |}

      it "applies to queries by `first`" do
        result = star_wars_query(query_string, { "first" => 100 })
        assert_equal(["Yavin", "Echo Base"], get_names(result))
        assert_equal(true, get_page_info(result)["hasNextPage"])

        # Max page size is applied _without_ `first`, also
        result = star_wars_query(query_string)
        assert_equal(["Yavin", "Echo Base"], get_names(result))
        assert_equal(true, get_page_info(result)["hasNextPage"], "hasNextPage is false when first is not specified")
      end

      it "applies to queries by `last`" do
        last_cursor = "Ng=="

        result = star_wars_query(query_string, { "last" => 100, "before" => last_cursor })
        assert_equal(["Death Star", "Shield Generator"], get_names(result))
        assert_equal(true, get_page_info(result)["hasPreviousPage"])

        result = star_wars_query(query_string, { "before" => last_cursor })
        assert_equal(["Yavin", "Echo Base"], get_names(result))
        assert_equal(false, get_page_info(result)["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

        third_cursor = "Mw"
        first_and_second_names = ["Yavin", "Echo Base"]
        result = star_wars_query(query_string, { "last" => 100, "before" => third_cursor })
        assert_equal(first_and_second_names, get_names(result))

        result = star_wars_query(query_string, { "before" => third_cursor })
        assert_equal(first_and_second_names, get_names(result))
      end
    end

    describe "applying default_max_page_size" do
      def get_names(result)
        result["data"]["rebels"]["bases"]["edges"].map { |e| e["node"]["name"] }
      end

      def get_page_info(result)
        result["data"]["rebels"]["bases"]["pageInfo"]
      end

      let(:query_string) {%|
        query getShips($first: Int, $after: String, $last: Int, $before: String){
          rebels {
            bases: basesWithDefaultMaxLimitArray(first: $first, after: $after, last: $last, before: $before) {
              edges {
                cursor
                node {
                  name
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
            }
          }
        }
      |}

      it "applies to queries by `first`" do
        result = star_wars_query(query_string, { "first" => 100 })
        assert_equal(["Yavin", "Echo Base", "Secret Hideout"], get_names(result))
        assert_equal(true, get_page_info(result)["hasNextPage"])

        # Max page size is applied _without_ `first`, also
        result = star_wars_query(query_string)
        assert_equal(["Yavin", "Echo Base", "Secret Hideout"], get_names(result))
        assert_equal(true, get_page_info(result)["hasNextPage"], "hasNextPage is false when first is not specified")
      end

      it "applies to queries by `last`" do
        last_cursor = "Ng=="

        result = star_wars_query(query_string, { "last" => 100, "before" => last_cursor })
        assert_equal(["Secret Hideout", "Death Star", "Shield Generator"], get_names(result))
        assert_equal(true, get_page_info(result)["hasPreviousPage"])

        result = star_wars_query(query_string, { "before" => last_cursor })
        assert_equal(["Yavin", "Echo Base", "Secret Hideout"], get_names(result))
        assert_equal(false, get_page_info(result)["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

        fourth_cursor = "NA=="
        first_second_and_third_names = ["Yavin", "Echo Base", "Secret Hideout"]
        result = star_wars_query(query_string, { "last" => 100, "before" => fourth_cursor })
        assert_equal(first_second_and_third_names, get_names(result))

        result = star_wars_query(query_string, { "before" => fourth_cursor })
        assert_equal(first_second_and_third_names, get_names(result))
      end
    end

    describe "bidirectional pagination" do
      it "provides bidirectional_pagination by default" do
        result = star_wars_query(query_string, { "first" => 1 })
        last_cursor = get_last_cursor(result)

        result = star_wars_query(query_string, { "first" => 3, "after" => last_cursor })
        assert_equal(true, get_page_info(result, "ships")["hasNextPage"])
        assert_equal(true, get_page_info(result, "ships")["hasPreviousPage"])

        # When going backwards, bi-directional pagination
        # returns true for `hasNextPage`
        last_cursor = get_last_cursor(result)
        result = star_wars_query(query_string, { "last" => 2, "before" => last_cursor })
        assert_equal(true, get_page_info(result, "ships")["hasNextPage"])
        assert_equal(true, get_page_info(result, "ships")["hasPreviousPage"])
      end

      it "returns correct page info when the before cursor belongs to the last element in the array" do
        result = star_wars_query(query_string, { "last" => 1 })

        last_cursor = get_last_cursor(result)

        result = star_wars_query(query_string, { "before" => last_cursor, "last" => 1 })

        assert_equal(true, get_page_info(result, "ships")["hasNextPage"])
        assert_equal(true, get_page_info(result, "ships")["hasPreviousPage"])
      end
    end
  end
end
