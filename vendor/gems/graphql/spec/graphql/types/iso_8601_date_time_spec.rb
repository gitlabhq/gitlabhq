# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::ISO8601DateTime do
  module DateTimeTest
    class DateTimeObject < GraphQL::Schema::Object
      field :year, Integer, null: false
      field :month, Integer, null: false
      field :day, Integer, null: false
      field :hour, Integer, null: false
      field :minute, Integer, method: :min, null: false
      field :second, Integer, method: :sec, null: false
      field :zone, String
      field :utc_offset, Integer, null: false
      field :iso8601, GraphQL::Types::ISO8601DateTime, null: false, method: :itself
    end

    class Query < GraphQL::Schema::Object
      field :parse_date, DateTimeObject do
        argument :date, GraphQL::Types::ISO8601DateTime
      end

      field :parse_date_time, DateTimeObject do
        argument :date, GraphQL::Types::ISO8601DateTime
      end

      field :parse_date_string, DateTimeObject do
        argument :date, GraphQL::Types::ISO8601DateTime
      end

      field :parse_date_time_string, DateTimeObject do
        argument :date, GraphQL::Types::ISO8601DateTime
      end

      field :invalid_date, DateTimeObject, null: false

      def parse_date(date:)
        # Resolve a Date object
        Date.parse(date.iso8601)
      end

      def parse_date_time(date:)
        # Resolve a Time object
        Time.parse(date.iso8601(3))
      end

      def parse_date_string(date:)
        # Resolve a Date string
        Date.parse(date.iso8601).iso8601
      end

      def parse_date_time_string(date:)
        # Resolve a DateTime string
        DateTime.parse(date.iso8601).iso8601
      end

      def invalid_date
        'abc'
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
    end
  end


  describe "as an input" do

    def parse_date(date_str)
      query_str = <<-GRAPHQL
      query($date: ISO8601DateTime!){
        parseDateTime(date: $date) {
          year
          month
          day
          hour
          minute
          second
          zone
          utcOffset
        }
      }
      GRAPHQL
      full_res = DateTimeTest::Schema.execute(query_str, variables: { date: date_str })
      full_res["errors"] || full_res["data"]["parseDateTime"]
    end

    it "parses valid dates" do
      res = parse_date("2018-06-07T09:31:42-07:00")
      expected_res = {
        "year" => 2018,
        "month" => 6,
        "day" => 7,
        "hour" => 9,
        "minute" => 31,
        "second" => 42,
        "zone" => nil,
        "utcOffset" => -25200,
      }
      assert_equal(expected_res, res)
    end

    it "parses valid dates with a timezone" do
      res = parse_date("2018-06-07T09:31:42Z")
      expected_res = {
        "year" => 2018,
        "month" => 6,
        "day" => 7,
        "hour" => 9,
        "minute" => 31,
        "second" => 42,
        "zone" => "UTC",
        "utcOffset" => 0,
      }
      assert_equal(expected_res, res)
    end

    it "parses dates without times" do
      res = parse_date("2018-06-07")
      # It uses the system default timezone when none is given
      system_default_tz = Date.iso8601("2018-06-07").to_time.zone
      system_default_offset = Date.iso8601("2018-06-07").to_time.utc_offset
      expected_res = {
        "year" => 2018,
        "month" => 6,
        "day" => 7,
        "hour" => 0,
        "minute" => 0,
        "second" => 0,
        "zone" => system_default_tz,
        "utcOffset" => system_default_offset,
      }
      assert_equal(expected_res, res)
    end

    it "parses dates without times or dashes" do
      res = parse_date("20180827")
      # It uses the system default timezone when none is given
      system_default_tz = Date.iso8601("2018-08-27").to_time.zone
      system_default_offset = Date.iso8601("2018-08-27").to_time.utc_offset
      expected_res = {
        "year" => 2018,
        "month" => 8,
        "day" => 27,
        "hour" => 0,
        "minute" => 0,
        "second" => 0,
        "zone" => system_default_tz,
        "utcOffset" => system_default_offset,
      }
      assert_equal(expected_res, res)
    end

    it "rejects partial times" do
      expected_errors = ["Variable $date of type ISO8601DateTime! was provided invalid value"]
      assert_equal expected_errors, parse_date("2018-06-07T12:12").map { |e| e["message"] }
      assert_equal expected_errors, parse_date("2018-06-07T12").map { |e| e["message"] }
    end

    it "adds an error for invalid dates" do
      expected_errors = ["Variable $date of type ISO8601DateTime! was provided invalid value"]

      assert_equal expected_errors, parse_date("2018-99-07T99:31:42Z").map { |e| e["message"] }
      assert_equal expected_errors, parse_date("xyz").map { |e| e["message"] }
      assert_equal expected_errors, parse_date(nil).map { |e| e["message"] }
      assert_equal expected_errors, parse_date([1,2,3]).map { |e| e["message"] }
    end

    it "handles array inputs gracefully" do
      query_str = <<-GRAPHQL
        {
          parseDateTime(date: ["A", "B", "C"]) {
            year
          }
        }
      GRAPHQL

      res = DateTimeTest::Schema.execute(query_str)
      expected_message = "Argument 'date' on Field 'parseDateTime' has an invalid value ([\"A\", \"B\", \"C\"]). Expected type 'ISO8601DateTime!'."
      assert_equal expected_message, res["errors"].first["message"]
    end
  end

  describe "as an output" do
    let(:date_str) { "2010-02-02T22:30:30-06:00" }
    let(:date_str_midnight) { Time.parse(Date.parse(date_str).iso8601).iso8601 }
    let(:query_str) do
      <<-GRAPHQL
      query($date: ISO8601DateTime!){
        parseDate(date: $date) {
          iso8601
        }
        parseDateTime(date: $date) {
          iso8601
        }
        parseDateString(date: $date) {
          iso8601
        }
        parseDateTimeString(date: $date) {
          iso8601
        }
      }
      GRAPHQL
    end
    let(:full_res) { DateTimeTest::Schema.execute(query_str, variables: { date: date_str }) }

    it 'serializes a Date object as an ISO8601 DateTime string' do
      assert_equal date_str_midnight, full_res["data"]["parseDate"]["iso8601"]
    end

    it 'serializes a DateTime object as an ISO8601 DateTime string' do
      assert_equal date_str, full_res["data"]["parseDateTime"]["iso8601"]
    end

    it 'serializes a Date string as an ISO8601 DateTime string' do
      assert_equal date_str_midnight, full_res["data"]["parseDateString"]["iso8601"]
    end

    it 'serializes a DateTime string as an ISO8601 DateTime string' do
      assert_equal date_str, full_res["data"]["parseDateTimeString"]["iso8601"]
    end

    describe "with time_precision = 3 (i.e. 'with milliseconds')" do
      before do
        @tp = GraphQL::Types::ISO8601DateTime.time_precision
        GraphQL::Types::ISO8601DateTime.time_precision = 3
      end

      after do
        GraphQL::Types::ISO8601DateTime.time_precision = @tp
      end

      it "returns a string" do
        query_str = <<-GRAPHQL
        query($date: ISO8601DateTime!){
          parseDateTime(date: $date) {
            iso8601
          }
        }
        GRAPHQL

        date_str = "2010-02-02T22:30:30.123-06:00"
        full_res = DateTimeTest::Schema.execute(query_str, variables: { date: date_str })
        assert_equal date_str, full_res["data"]["parseDateTime"]["iso8601"]
      end
    end

    describe "with Date value" do
      it "raises an error" do
        query_str = <<-GRAPHQL
        query {
          invalidDate {
            iso8601
          }
        }
        GRAPHQL

        err = assert_raises(GraphQL::Error) do
          DateTimeTest::Schema.execute(query_str)
        end
        assert_equal err.message, 'An incompatible object (String) was given to GraphQL::Types::ISO8601DateTime. Make sure that only Times, Dates, DateTimes, and well-formatted Strings are used with this type. (no time information in "abc")'
      end
    end
  end

  describe "structure" do
    it "is in introspection" do
      introspection_res = DateTimeTest::Schema.execute <<-GRAPHQL
      {
        __type(name: "ISO8601DateTime") {
          name
          kind
        }
      }
      GRAPHQL

      expected_res = { "name" => "ISO8601DateTime", "kind" => "SCALAR"}
      assert_equal expected_res, introspection_res["data"]["__type"]
    end
  end
end
