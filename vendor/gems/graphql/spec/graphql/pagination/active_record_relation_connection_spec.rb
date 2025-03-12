# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::ActiveRecordRelationConnection do
    class RelationConnectionWithTotalCount < GraphQL::Pagination::ActiveRecordRelationConnection
      def total_count
        if items.respond_to?(:unscope)
          items.unscope(:order).count(:all)
        else
          # rails 3
          items.count
        end
      end
    end

    let(:schema) {
      ConnectionAssertions.build_schema(
        connection_class: GraphQL::Pagination::ActiveRecordRelationConnection,
        total_count_connection_class: RelationConnectionWithTotalCount,
        get_items: -> {
          if Food.respond_to?(:scoped)
            Food.scoped.limit(limit) # Rails 3-friendly version of .all
          else
            Food.all.limit(limit)
          end
        }
      )
    }

    let(:limit) { nil }

    include ConnectionAssertions

    before do
      if Food.count == 0 # Backwards-compat version of `.none?`
        ConnectionAssertions::NAMES.each { |n| Food.create!(name: n) }
      end
    end

    it "maintains an application-provided offset" do
      results = schema.execute("{
        offsetItems(first: 3) {
          nodes { name }
          pageInfo { endCursor }
        }
      }")
      assert_equal ["Cucumber", "Dill", "Eggplant"], results["data"]["offsetItems"]["nodes"].map { |n| n["name"] }
      end_cursor = results["data"]["offsetItems"]["pageInfo"]["endCursor"]

      results = schema.execute("{
        offsetItems(first: 3, after: #{end_cursor.inspect}) {
          nodes { name }
        }
      }")
      assert_equal ["Fennel", "Ginger", "Horseradish"], results["data"]["offsetItems"]["nodes"].map { |n| n["name"] }

      results = schema.execute("{
        offsetItems(last: 2, before: #{end_cursor.inspect}) {
          nodes { name }
        }
      }")
      assert_equal ["Cucumber", "Dill"], results["data"]["offsetItems"]["nodes"].map { |n| n["name"] }
    end

    describe 'with application-provided limit, which is smaller than the max_page_size' do
      let(:limit) { 1 }

      it "maintains an application-provided limit" do
        results = schema.execute("{
          limitedItems {
            nodes { name }
          }
        }")
        assert_equal ["Avocado"], results["data"]["limitedItems"]["nodes"].map { |n| n["name"] }
      end
    end

    describe 'with application-provided limit, which is larger than the max_page_size' do
      let(:limit) { 3 }

      it "applies a field-level max-page-size configuration" do
        results = schema.execute("{
          limitedItems {
            nodes { name }
          }
        }")
        assert_equal ["Avocado", "Beet"], results["data"]["limitedItems"]["nodes"].map { |n| n["name"] }
      end
    end


    it "doesn't run pageInfo queries when not necessary" do
      results = nil
      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            __typename
          }
        }")
      end
      assert_equal "ItemConnection", results["data"]["items"]["__typename"]
      assert_equal "", log, "No queries are executed when no data is requested"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
          }
        }")
      end
      assert_equal true, results["data"]["items"]["pageInfo"]["hasNextPage"]
      assert_equal false, results["data"]["items"]["pageInfo"]["hasPreviousPage"]
      assert_equal 1, log.split("\n").size, "It runs only one query"
      assert_equal 1, log.squeeze.scan("SELECT 1 AS").size, "It's an exist query (#{log.inspect})"

      log = with_active_record_log do
        results = schema.execute("{
          items(last: 3) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
          }
        }")
      end
      assert_equal true, results["data"]["items"]["pageInfo"]["hasPreviousPage"]
      assert_equal false, results["data"]["items"]["pageInfo"]["hasNextPage"]
      assert_equal 1, log.split("\n").size, "It runs only one query"
      assert_equal 1, log.scan("COUNT(").size, "It's a count query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            nodes {
              __typename
            }
          }
        }")
      end
      assert_equal ["Item", "Item", "Item"], results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal 1, log.split("\n").size, "It runs only one query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 11, maxPageSizeOverride: 11) {
            nodes {
              __typename
            }
            pageInfo {
              hasNextPage
            }
          }
        }")
      end
      assert_equal ["Item"] * 10, results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal 1, log.split("\n").size, "It runs only one query when less than total count is requested"
      assert_equal 0, log.scan("COUNT(").size, "It runs no count query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            nodes {
              __typename
            }
            pageInfo {
              hasNextPage
            }
          }
        }")
      end
      # This currently runs one query to load the nodes, then another one to count _just beyond_ the nodes.
      # A better implementation would load `first + 1` nodes and use that to set `has_next_page`.
      assert_equal ["Item", "Item", "Item"], results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal 2, log.split("\n").size, "It runs two queries -- TODO this could be better"
    end

    describe "already-loaded ActiveRecord relations" do
      ALREADY_LOADED_QUERY_STRING = "
      query($first: Int, $after: String, $last: Int, $before: String) {
            preloadedItems(first: $first, after: $after, last: $last, before: $before) {
              pageInfo {
                hasPreviousPage
                hasNextPage
                endCursor
              }
              nodes { __typename }
            }
          }
      "
      it "only runs one query for already-loaded unbounded queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING)
        end
        # The default_page_size of 4 is applied to the results
        assert_equal 4, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
      end

      it "only runs one query for already-loaded `last:...` queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { last: 1 })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
      end

      it "only runs one query for already-loaded `first:... / after:` queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { first: 1 })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"

        cursor = results["data"]["preloadedItems"]["pageInfo"]["endCursor"]
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { first: 1, after: cursor })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
        assert_equal "[\"2\"]+nonce", results["data"]["preloadedItems"]["pageInfo"]["endCursor"], "it makes the right cursor"
      end

      let(:schema) {
        ConnectionAssertions.build_schema(
          connection_class: GraphQL::Pagination::ActiveRecordRelationConnection,
          total_count_connection_class: RelationConnectionWithTotalCount,
          get_items: -> {
            relation = if Food.respond_to?(:scoped)
              Food.scoped # Rails 3-friendly version of .all
            else
              Food.all
            end
            relation.load
            relation
          }
        )
      }

      include ConnectionAssertions
    end
  end
end
