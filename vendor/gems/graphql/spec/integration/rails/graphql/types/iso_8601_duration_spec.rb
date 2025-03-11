# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::ISO8601Duration do
  module DurationTest
    class Schema < GraphQL::Schema
      def self.type_error(err, ctx)
        raise err
      end
    end
  end

  let(:context) { GraphQL::Query.new(DurationTest::Schema, "{ __typename }").context }

  # 3 years, 6 months, 4 days, 12 hours, 30 minutes, and 5.12345 seconds
  let (:duration_str) { "P3Y6M4DT12H30M5.12345S" }
  let (:duration) { ActiveSupport::Duration.parse(duration_str) }

  describe "coerce_result" do
    describe "coercing ActiveSupport::Duration" do
      it "coerces defaulting to same precision as input precision" do
        assert_equal duration_str, GraphQL::Types::ISO8601Duration.coerce_result(duration, context)
      end

      it "coerces with seconds_precision when set" do
        initial_precision = GraphQL::Types::ISO8601Duration.seconds_precision

        GraphQL::Types::ISO8601Duration.seconds_precision = 2

        assert_equal duration.iso8601(precision: 2), GraphQL::Types::ISO8601Duration.coerce_result(duration, context)

        GraphQL::Types::ISO8601Duration.seconds_precision = initial_precision
      end
    end

    describe "coercing String" do
      it "defaults to same precision as input precision" do
        assert_equal duration_str, GraphQL::Types::ISO8601Duration.coerce_result(duration_str, context)
      end

      it "coerces with seconds_precision when set" do
        initial_precision = GraphQL::Types::ISO8601Duration.seconds_precision

        GraphQL::Types::ISO8601Duration.seconds_precision = 2

        assert_equal duration.iso8601(precision: 2), GraphQL::Types::ISO8601Duration.coerce_result(duration_str, context)

        GraphQL::Types::ISO8601Duration.seconds_precision = initial_precision
      end
    end

    describe "coercing incompatible objects" do
      it "raises GraphQL::Error" do
        assert_raises GraphQL::Error do
          GraphQL::Types::ISO8601Duration.coerce_result(Object.new, context)
        end
      end
    end
  end

  describe "coerce_input" do
    describe "coercing ActiveSupport::Duration" do
      it "returns itself" do
        assert_equal duration, GraphQL::Types::ISO8601Duration.coerce_input(duration, context)
      end
    end

    describe "coercing nil" do
      it "returns nil" do
        assert_nil GraphQL::Types::ISO8601Duration.coerce_input(nil, context)
      end
    end

    describe "coercing String" do
      it "returns a ActiveSupport::Duration for ISO8601-formatted durations" do
        assert_equal duration, GraphQL::Types::ISO8601Duration.coerce_input(duration_str, context)
      end

      it "raises GraphQL::DurationEncodingError for incorrectly formatted strings" do
        assert_raises GraphQL::DurationEncodingError do
          # ISO8601 dates are not durations
          GraphQL::Types::ISO8601Duration.coerce_input("2007-03-01T13:00:00Z", context)
        end
      end
    end

    describe "coercing other objects" do
      it "raises GraphQL::DurationEncodingError" do
        assert_raises GraphQL::DurationEncodingError do
          # ISO8601 dates are not durations
          GraphQL::Types::ISO8601Duration.coerce_input(Object.new, context)
        end
      end
    end
  end

  describe "when ActiveSupport is not defined" do
    it "coerce_result and coerce_input raise GraphQL::Error" do
      old_active_support = defined?(ActiveSupport) ? ActiveSupport : nil
      Object.send(:remove_const, :ActiveSupport) if defined?(ActiveSupport)

      assert_raises GraphQL::Error do
        GraphQL::Types::ISO8601Duration.coerce_result("", context)
      end

      assert_raises GraphQL::Error do
        GraphQL::Types::ISO8601Duration.coerce_input("", context)
      end

      ActiveSupport = old_active_support unless old_active_support.nil?
    end
  end
end
