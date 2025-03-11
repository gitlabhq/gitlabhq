# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::Source do
  class FailsToLoadSource < GraphQL::Dataloader::Source
    def fetch(keys)
      dataloader.with(FailsToLoadSource).load_all(keys)
    end
  end

  it "raises an error when it tries too many times to sync" do
    dl = GraphQL::Dataloader.new
    dl.append_job { dl.with(FailsToLoadSource).load(1) }
    err = assert_raises RuntimeError do
      dl.run
    end
    expected_message = "FailsToLoadSource#sync tried 1000 times to load pending keys ([1]), but they still weren't loaded. There is likely a circular dependency."
    assert_equal expected_message, err.message

    dl = GraphQL::Dataloader.new(fiber_limit: 10000)
    dl.append_job { dl.with(FailsToLoadSource).load(1) }
    err = assert_raises RuntimeError do
      dl.run
    end
    expected_message = "FailsToLoadSource#sync tried 1000 times to load pending keys ([1]), but they still weren't loaded. There is likely a circular dependency or `fiber_limit: 10000` is set too low."
    assert_equal expected_message, err.message
  end

  it "is pending when waiting for false and nil" do
    dl = GraphQL::Dataloader.new
    dl.with(FailsToLoadSource).request(nil)

    source_cache = dl.instance_variable_get(:@source_cache)
    source_cache_for_source = source_cache[FailsToLoadSource]

    # The value of this changed in Ruby 3.3.3, see https://bugs.ruby-lang.org/issues/20180
    # In previous versions, it was `[{}]`, but now it's `[]`
    empty_batch_key = [*[], **{}]
    source_inst = source_cache_for_source[empty_batch_key]
    assert_instance_of FailsToLoadSource, source_inst, "The cache includes a pending source (#{source_cache_for_source.inspect})"
    assert source_inst.pending?
  end

  class CustomKeySource < GraphQL::Dataloader::Source
    def result_key_for(record)
      record[:id]
    end

    def fetch(records)
      records.map { |r| r[:value] * 10 }
    end
  end

  it "uses a custom key when configured" do
    values = nil

    GraphQL::Dataloader.with_dataloading do |dl|
      first_req = dl.with(CustomKeySource).request({ id: 1, value: 10 })
      second_rec = dl.with(CustomKeySource).request({ id: 2, value: 20 })
      third_rec = dl.with(CustomKeySource).request({id: 1, value: 30 })

      values = [
        first_req.load,
        second_rec.load,
        third_rec.load
      ]
    end

    # There wasn't a `300` because the third requested value was de-duped to the first one.
    assert_equal [100, 200, 100], values
  end

  class NoDataloaderSchema < GraphQL::Schema
    class ThingSource < GraphQL::Dataloader::Source
      def fetch(ids)
        ids.map { |id| { name: "Thing-#{id}" } }
      end
    end

    class Thing < GraphQL::Schema::Object
      field :name, String
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing do
        argument :id, ID
      end

      def thing(id:)
        context.dataloader.with(ThingSource).load(id)
      end
    end
    query(Query)
  end

  it "raises an error when used without a dataloader" do
    err = assert_raises GraphQL::Error do
      NoDataloaderSchema.execute("{ thing(id: 1) { name } }")
    end

    expected_message = "GraphQL::Dataloader is not running -- add `use GraphQL::Dataloader` to your schema to use Dataloader sources."
    assert_equal expected_message, err.message
  end
end
