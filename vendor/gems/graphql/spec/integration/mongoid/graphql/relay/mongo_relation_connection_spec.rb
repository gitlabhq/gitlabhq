# frozen_string_literal: true
require 'spec_helper'

describe "GraphQL::Relay::MongoRelationConnection" do
  def get_names(result)
    ships = result["data"]["federation"]["bases"]["edges"]
    ships.map { |e| e["node"]["name"] }
  end

  def get_residents(ship)
    ship["residents"]["edges"].map { |e| e["node"]["name"] }
  end

  def get_ships_residents(result)
    ships = result["data"]["federation"]["bases"]["edges"]
    Hash[ships.map { |e| [e["node"]["name"], get_residents(e["node"])] }]
  end

  def get_page_info(result)
    result["data"]["federation"]["bases"]["pageInfo"]
  end

  def get_first_cursor(result)
    result["data"]["federation"]["bases"]["edges"].first["cursor"]
  end

  def get_last_cursor(result)
    result["data"]["federation"]["bases"]["edges"].last["cursor"]
  end

  describe "results" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String,  $nameIncludes: String){
        federation {
          bases(first: $first, after: $after, last: $last, before: $before, nameIncludes: $nameIncludes) {
            ... basesConnection
          }
        }
      }

      fragment basesConnection on BasesConnectionWithTotalCount {
        totalCount,
        edges {
          cursor
          node {
            name
          }
        },
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
      }
    |}

    it 'limits the result' do
      result = star_trek_query(query_string, { "first" => 2 })
      assert_equal(2, get_names(result).length)
      assert_equal(true, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ", get_page_info(result)["startCursor"])
      assert_equal("Mg", get_page_info(result)["endCursor"])
      assert_equal("MQ", get_first_cursor(result))
      assert_equal("Mg", get_last_cursor(result))

      result = star_trek_query(query_string, { "first" => 3 })
      assert_equal(3, get_names(result).length)
      assert_equal(false, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ", get_page_info(result)["startCursor"])
      assert_equal("Mw", get_page_info(result)["endCursor"])
      assert_equal("MQ", get_first_cursor(result))
      assert_equal("Mw", get_last_cursor(result))
    end

    it 'provides custom fields on the connection type' do
      result = star_trek_query(query_string, { "first" => 2 })
      assert_equal(
        StarTrek::Base.where(faction_id: 1).count,
        result["data"]["federation"]["bases"]["totalCount"]
      )
    end

    it "provides bidirectional_pagination by default" do
      result = star_trek_query(query_string, { "first" => 1 })
      last_cursor = get_last_cursor(result)

      result = star_trek_query(query_string, { "first" => 1, "after" => last_cursor })
      assert_equal true, get_page_info(result)["hasNextPage"]
      assert_equal true, get_page_info(result)["hasPreviousPage"]

      last_cursor = get_last_cursor(result)
      result =  star_trek_query(query_string, { "last" => 1, "before" => last_cursor })
      assert_equal true, get_page_info(result)["hasNextPage"]
      assert_equal false, get_page_info(result)["hasPreviousPage"]

      result = star_trek_query(query_string, { "first" => 100 })
      last_cursor = get_last_cursor(result)

      result = star_trek_query(query_string, { "last" => 1, "before" => last_cursor })
      assert_equal true, get_page_info(result)["hasNextPage"]
      assert_equal true, get_page_info(result)["hasPreviousPage"]
    end

    it 'slices the result' do
      result = star_trek_query(query_string, { "first" => 2 })
      assert_equal(["Deep Space Station K-7", "Regula I"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = star_trek_query(query_string, { "after" => last_cursor, "first" => 2 })
      assert_equal(["Deep Space Nine"], get_names(result))

      last_cursor = get_last_cursor(result)

      result = star_trek_query(query_string, { "before" => last_cursor, "last" => 1 })
      assert_equal(["Regula I"], get_names(result))

      result = star_trek_query(query_string, { "before" => last_cursor, "last" => 2 })
      assert_equal(["Deep Space Station K-7", "Regula I"], get_names(result))

      result = star_trek_query(query_string, { "before" => last_cursor, "last" => 10 })
      assert_equal(["Deep Space Station K-7", "Regula I"], get_names(result))

      result = star_trek_query(query_string, { "last" => 2 })
      assert_equal(["Regula I", "Deep Space Nine"], get_names(result))

      result = star_trek_query(query_string, { "last" => 10 })
      assert_equal(["Deep Space Station K-7", "Regula I", "Deep Space Nine"], get_names(result))
      assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasNextPage"])
      assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasPreviousPage"])
    end

    it 'works with before and after specified together' do
      result = star_trek_query(query_string, { "first" => 2 })
      assert_equal(["Deep Space Station K-7", "Regula I"], get_names(result))

      first_cursor = get_last_cursor(result)

      # There is no records between before and after if they point to the same cursor
      result = star_trek_query(query_string, { "before" => first_cursor, "after" => first_cursor, "last" => 2 })
      assert_equal([], get_names(result))

      result = star_trek_query(query_string, { "after" => first_cursor, "first" => 2 })
      assert_equal(["Deep Space Nine"], get_names(result))

      second_cursor = get_last_cursor(result)

      result = star_trek_query(query_string, { "after" => first_cursor, "before" => second_cursor, "first" => 3 })
      assert_equal([], get_names(result)) # TODO: test fails. fixme
    end

    it 'handles cursors above the bounds of the array' do
      overreaching_cursor = Base64.strict_encode64("100")
      result = star_trek_query(query_string, { "after" => overreaching_cursor, "first" => 2 })
      assert_equal([], get_names(result))
    end

    it 'handles cursors below the bounds of the array' do
      underreaching_cursor = Base64.strict_encode64("1")
      result = star_trek_query(query_string, { "before" => underreaching_cursor, "first" => 2 })
      assert_equal([], get_names(result))
    end


    it 'handles grouped connections with only last argument' do
      grouped_conn_query = <<-GRAPHQL
      query {
        newestBasesGroupedByFaction(last: 2) {
          edges {
            node {
              name
            }
          }
        }
      }
      GRAPHQL

      result = star_trek_query(grouped_conn_query)
      names = result['data']['newestBasesGroupedByFaction']['edges'].map { |edge| edge['node']['name'] }
      assert_equal(['Ganalda Space Station', 'Deep Space Nine'], names)
    end

    it "applies custom arguments" do
      result = star_trek_query(query_string, { "first" => 1, "nameIncludes" => "eep" })
      assert_equal(["Deep Space Station K-7"], get_names(result))

      after = get_last_cursor(result)

      result = star_trek_query(query_string, { "first" => 2, "nameIncludes" => "eep", "after" => after  })
      assert_equal(["Deep Space Nine"], get_names(result))
      before = get_last_cursor(result)

      result = star_trek_query(query_string, { "last" => 1, "nameIncludes" => "eep", "before" => before })
      assert_equal(["Deep Space Station K-7"], get_names(result))
    end

    it 'works without first/last/after/before' do
      result = star_trek_query(query_string)

      assert_equal(3, result["data"]["federation"]["bases"]["edges"].length)
    end

    describe "applying max_page_size" do
      let(:query_string) {%|
        query getBases($first: Int, $after: String, $last: Int, $before: String){
          federation {
            bases: basesWithMaxLimitRelation(first: $first, after: $after, last: $last, before: $before) {
              ... basesConnection
            }
          }
        }

        fragment basesConnection on BaseConnection {
          edges {
            cursor
            node {
              name
            }
          },
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      |}

      it "applies to queries by `first`" do
        result = star_trek_query(query_string, { "first" => 100 })
        assert_equal(2, result["data"]["federation"]["bases"]["edges"].size)
        assert_equal(true, result["data"]["federation"]["bases"]["pageInfo"]["hasNextPage"])

        # Max page size is applied _without_ `first`, also
        result = star_trek_query(query_string)
        assert_equal(2, result["data"]["federation"]["bases"]["edges"].size)
        assert_equal(true, result["data"]["federation"]["bases"]["pageInfo"]["hasNextPage"], "hasNextPage is false when first is not specified")
      end

      it "applies to queries by `last`" do
        second_to_last_two_names = ["Firebase P'ok", "Ganalda Space Station"]
        first_and_second_names = ["Deep Space Station K-7", "Regula I"]

        last_cursor = "Ng=="
        result = star_trek_query(query_string, { "last" => 100, "before" => last_cursor })
        assert_equal(second_to_last_two_names, get_names(result))
        assert_equal(true, result["data"]["federation"]["bases"]["pageInfo"]["hasPreviousPage"])

        result = star_trek_query(query_string, { "before" => last_cursor })
        assert_equal(first_and_second_names, get_names(result))
        assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

        third_cursor = "Mw"
        result = star_trek_query(query_string, { "last" => 100, "before" => third_cursor })
        assert_equal(first_and_second_names, get_names(result))

        result = star_trek_query(query_string, { "before" => third_cursor })
        assert_equal(first_and_second_names, get_names(result))
      end
    end

    describe "applying default_max_page_size" do
      let(:query_string) {%|
        query getBases($first: Int, $after: String, $last: Int, $before: String){
          federation {
            bases: basesWithDefaultMaxLimitRelation(first: $first, after: $after, last: $last, before: $before) {
              ... basesConnection
            }
          }
        }

        fragment basesConnection on BaseConnection {
          edges {
            cursor
            node {
              name
            }
          },
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
        |}

      it "applies to queries by `first`" do
        result = star_trek_query(query_string, { "first" => 100 })
        assert_equal(3, result["data"]["federation"]["bases"]["edges"].size)
        assert_equal(true, result["data"]["federation"]["bases"]["pageInfo"]["hasNextPage"])

        # Max page size is applied _without_ `first`, also
        result = star_trek_query(query_string)
        assert_equal(3, result["data"]["federation"]["bases"]["edges"].size)
        assert_equal(true, result["data"]["federation"]["bases"]["pageInfo"]["hasNextPage"], "hasNextPage is false when first is not specified")
      end

      it "applies to queries by `last`" do
        second_to_last_three_names = ["Deep Space Nine", "Firebase P'ok", "Ganalda Space Station"]
        first_second_and_third_names = ["Deep Space Station K-7", "Regula I", "Deep Space Nine"]

        last_cursor = "Ng=="
        result = star_trek_query(query_string, { "last" => 100, "before" => last_cursor })
        assert_equal(second_to_last_three_names, get_names(result))
        assert_equal(true, result["data"]["federation"]["bases"]["pageInfo"]["hasPreviousPage"])

        result = star_trek_query(query_string, { "before" => last_cursor })
        assert_equal(first_second_and_third_names, get_names(result))
        assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

        fourth_cursor = "NA=="
        result = star_trek_query(query_string, { "last" => 100, "before" => fourth_cursor })
        assert_equal(first_second_and_third_names, get_names(result))

        result = star_trek_query(query_string, { "before" => fourth_cursor })
        assert_equal(first_second_and_third_names, get_names(result))
      end
    end
  end

  describe "applying a max_page_size bigger than the results" do
    let(:query_string) {%|
      query getBases($first: Int, $after: String, $last: Int, $before: String){
        federation {
          bases: basesWithLargeMaxLimitRelation(first: $first, after: $after, last: $last, before: $before) {
            ... basesConnection
          }
        }
      }

      fragment basesConnection on BaseConnection {
        edges {
          cursor
          node {
            name
          }
        },
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
      }
      |}

    it "applies to queries by `first`" do
      result = star_trek_query(query_string, { "first" => 100 })
      assert_equal(6, result["data"]["federation"]["bases"]["edges"].size)
      assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasNextPage"])

      # Max page size is applied _without_ `first`, also
      result = star_trek_query(query_string)
      assert_equal(6, result["data"]["federation"]["bases"]["edges"].size)
      assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasNextPage"], "hasNextPage is false when first is not specified")
    end

    it "applies to queries by `last`" do
      all_names = ["Deep Space Station K-7", "Regula I", "Deep Space Nine", "Firebase P'ok", "Ganalda Space Station", "Rh'Ihho Station"]

      last_cursor = "Ng=="
      result = star_trek_query(query_string, { "last" => 100, "before" => last_cursor })
      assert_equal(all_names[0..4], get_names(result))
      assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasPreviousPage"])

      result = star_trek_query(query_string, { "last" => 100 })
      assert_equal(all_names, get_names(result))
      assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasPreviousPage"])

      result = star_trek_query(query_string, { "before" => last_cursor })
      assert_equal(all_names[0..4], get_names(result))
      assert_equal(false, result["data"]["federation"]["bases"]["pageInfo"]["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

      fourth_cursor = "NA=="
      result = star_trek_query(query_string, { "last" => 100, "before" => fourth_cursor })
      assert_equal(all_names[0..2], get_names(result))

      result = star_trek_query(query_string, { "before" => fourth_cursor })
      assert_equal(all_names[0..2], get_names(result))
    end
  end

  describe "without a block" do
    let(:query_string) {%|
      {
        federation {
          basesClone(first: 10) {
            edges {
              node {
                name
              }
            }
          }
        }
    }|}
    it "uses default resolve" do
      result = star_trek_query(query_string)
      bases = result["data"]["federation"]["basesClone"]["edges"]
      assert_equal(3, bases.length)
    end
  end

  describe "custom ordering" do
    let(:query_string) {%|
      query getBases {
        federation {
          basesByName(first: 30) { ... basesFields }
          bases(first: 30) { ... basesFields2 }
        }
      }
      fragment basesFields on BaseConnection {
        edges {
          node {
            name
          }
        }
      }
      fragment basesFields2 on BasesConnectionWithTotalCount {
        edges {
          node {
            name
          }
        }
      }
    |}

    def get_names(result, field_name)
      bases = result["data"]["federation"][field_name]["edges"]
      bases.map { |b| b["node"]["name"] }
    end

    it "applies the default value" do
      result = star_trek_query(query_string)
      bases_by_id   = ["Deep Space Station K-7", "Regula I", "Deep Space Nine"]
      bases_by_name = ["Deep Space Nine", "Deep Space Station K-7", "Regula I"]

      assert_equal(bases_by_id, get_names(result, "bases"))
      assert_equal(bases_by_name, get_names(result, "basesByName"))
    end
  end

  describe "relations" do
    let(:query_string) {%|
      query getShips {
        federation {
          bases {
            ... basesConnection
          }
        }
      }

      fragment basesConnection on BasesConnectionWithTotalCount {
        edges {
          cursor
          node {
            name
            residents {
              edges {
                node {
                  name
                }
              }
            }
          }
        }
      }
    |}

    it "Mongoid::Association::Referenced::HasMany::Targets::Enumerable" do
      result = star_trek_query(query_string)
      assert_equal get_ships_residents(result), {
        "Deep Space Station K-7" => [
          "Shir th'Talias",
          "Lurry",
          "Mackenzie Calhoun"
        ],
        "Regula I" => [
          "V. Madison",
          "D. March",
          "C. Marcus"
        ],
        "Deep Space Nine" => []
      }
    end
  end
end
