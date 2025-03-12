# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader do
  if defined?(ActiveRecord::Promise) && ENV['DATABASE'] == 'POSTGRESQL' # Rails 7.1+
    class RailsPromiseSchema < GraphQL::Schema
      class LoadAsyncSource < GraphQL::Dataloader::Source
        LOG = []
        def fetch(relations)
          relations.each do |rel|
            LOG << Time.now
            rel.load_async
          end
          dataloader.yield
          relations.each do |rel|
            rel.load
            LOG << Time.now
          end
        end
      end

      class SleepSource < GraphQL::Dataloader::Source
        def initialize(duration)
          @duration = duration
        end

        def fetch(durations)
          # puts  "[#{Time.now.to_f}] Starting #{durations}"
          promise = ::Food.async_find_by_sql("SELECT pg_sleep(#{durations.first})")
          # puts "[#{Time.now.to_f}] Yielding #{durations}"
          dataloader.yield
          # puts "[#{Time.now.to_f}] Finishing #{durations}"
          promise.value
          durations
        end
      end
      class Query < GraphQL::Schema::Object
        field :sleep, Float do
          argument :duration, Float
        end

        def sleep(duration:)
          dataloader.with(SleepSource, duration).load(duration)
        end

        field :things, Integer do
          argument :first, Integer
        end

        def things(first:)
          relation = Food
            .where(name: "Zucchini")
            .select("pg_sleep(0.3)")
            .limit(first)
          items = dataloader.with(LoadAsyncSource).load(relation)
          items.size
        end
      end

      query(Query)
      use GraphQL::Dataloader
    end

    before do
      Food.create!(name: "Zucchini")
      RailsPromiseSchema::LoadAsyncSource::LOG.clear
    end

    after do
      Food.find_by(name: "Zucchini").destroy
    end

    it "Supports async queries" do
      assert ActiveRecord::Base.connection.async_enabled?, "ActiveRecord must support real async queries"
    end

    describe "using ActiveRecord::Promise for manual parallelism" do
      it "runs queries in parallel" do
        query_str = "
        {
          s1: sleep(duration: 0.1)
          s2: sleep(duration: 0.2)
          s3: sleep(duration: 0.3)
        }"
        t1 = Time.now
        result = RailsPromiseSchema.execute(query_str)
        t2 = Time.now
        assert_equal({ "s1" => 0.1, "s2" => 0.2, "s3" => 0.3}, result["data"])
        assert_in_delta 0.3, t2 - t1, 0.06, "Sleeps were in parallel"
      end
    end

    describe "using load_async for parallelism" do
      it "runs queries in parallel" do
        query_str = "
        {
          t1: things(first: 5)
          t2: things(first: 10)
          t3: things(first: 100)
        }"
        t1 = Time.now
        result = RailsPromiseSchema.execute(query_str)
        t2 = Time.now

        load_async_1, load_async_2, load_async_3, load_1, load_2, load_3 = RailsPromiseSchema::LoadAsyncSource::LOG
        assert_in_delta load_async_1, load_async_2, 0.06, "load_async happened first"
        assert_in_delta load_async_1, load_async_3, 0.06, "the third load_async happened right after"

        assert_in_delta load_async_1, load_1, 0.35, "load came 0.3s after"
        assert_in_delta load_1, load_2, 0.06, "the second load didn't have to wait because it was already done"
        assert_in_delta load_1, load_3, 0.06, "the third load didn't have to wait because it was already done"

        assert_equal({ "t1" => 1, "t2" => 1, "t3" => 1}, result["data"])
        assert_in_delta 0.3, t2 - t1, 0.06, "Sleeps were in parallel"
      end
    end
  end
end
