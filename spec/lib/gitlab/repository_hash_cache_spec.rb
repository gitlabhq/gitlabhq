# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::RepositoryHashCache, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project) }

  let(:repository) { project.repository }
  let(:namespace) { "#{repository.full_path}:#{project.id}" }
  let(:cache) { described_class.new(repository) }
  let(:test_hash) do
    { "test" => "value" }
  end

  describe "#cache_key" do
    subject { cache.cache_key(:example) }

    it "includes the namespace" do
      is_expected.to eq("example:#{namespace}:hash")
    end

    context "with a given namespace" do
      let(:extra_namespace) { "my:data" }
      let(:cache) { described_class.new(repository, extra_namespace: extra_namespace) }

      it "includes the full namespace" do
        is_expected.to eq("example:#{namespace}:#{extra_namespace}:hash")
      end
    end
  end

  describe "#delete" do
    subject { cache.delete(:example) }

    context "key exists" do
      before do
        cache.write(:example, test_hash)
      end

      it { is_expected.to eq(1) }

      it "deletes the given key from the cache" do
        subject

        expect(cache.read_members(:example, ["test"])).to eq({ "test" => nil })
      end
    end

    context "key doesn't exist" do
      it { is_expected.to eq(0) }
    end

    context "multiple keys" do
      before do
        cache.write(:test1, test_hash)
        cache.write(:test2, test_hash)
      end

      it "deletes multiple keys" do
        cache.delete(:test1, :test2)

        expect(cache.read_members(:test1, ["test"])).to eq("test" => nil)
        expect(cache.read_members(:test2, ["test"])).to eq("test" => nil)
      end

      it "returns deleted key count" do
        expect(cache.delete(:test1, :test2)).to eq(2)
      end
    end
  end

  describe "#key?" do
    subject { cache.key?(:example, "test") }

    context "key exists" do
      before do
        cache.write(:example, test_hash)
      end

      it { is_expected.to be(true) }
    end

    context "key doesn't exist" do
      it { is_expected.to be(false) }
    end
  end

  describe "#read_members" do
    subject { cache.read_members(:example, keys) }

    let(:keys) { %w(test missing) }

    context "all data is cached" do
      before do
        cache.write(:example, test_hash.merge({ "missing" => false }))
      end

      it { is_expected.to eq({ "test" => "value", "missing" => "false" }) }
    end

    context "partial data is cached" do
      before do
        cache.write(:example, test_hash)
      end

      it { is_expected.to eq({ "test" => "value", "missing" => nil }) }
    end

    context "no data is cached" do
      it { is_expected.to eq({ "test" => nil, "missing" => nil }) }
    end

    context "empty keys are passed for some reason" do
      let(:keys) { [] }

      it "raises an error" do
        expect { subject }.to raise_error(Gitlab::RepositoryHashCache::InvalidKeysProvidedError)
      end
    end
  end

  describe "#write" do
    subject { cache.write(:example, test_hash) }

    it { is_expected.to be(true) }

    it "actually writes stuff to Redis" do
      subject

      expect(cache.read_members(:example, ["test"])).to eq(test_hash)
    end
  end

  describe "#fetch_and_add_missing" do
    subject do
      cache.fetch_and_add_missing(:example, keys) do |missing_keys, hash|
        missing_keys.each do |key|
          hash[key] = "was_missing"
        end
      end
    end

    let(:keys) { %w(test) }

    it "records metrics" do
      # Here we expect it to receive "test" as a missing key because we
      # don't write to the cache before this test
      expect(cache).to receive(:record_metrics).with(:example, { "test" => "was_missing" }, ["test"])

      subject
    end

    context "fully cached" do
      let(:keys) { %w(test another) }

      before do
        cache.write(:example, test_hash.merge({ "another" => "not_missing" }))
      end

      it "returns a hash" do
        is_expected.to eq({ "test" => "value", "another" => "not_missing" })
      end

      it "doesn't write to the cache" do
        expect(cache).not_to receive(:write)

        subject
      end
    end

    context "partially cached" do
      let(:keys) { %w(test missing) }

      before do
        cache.write(:example, test_hash)
      end

      it "returns a hash" do
        is_expected.to eq({ "test" => "value", "missing" => "was_missing" })
      end

      it "writes to the cache" do
        expect(cache).to receive(:write).with(:example, { "missing" => "was_missing" })

        subject
      end
    end

    context "uncached" do
      let(:keys) { %w(test missing) }

      it "returns a hash" do
        is_expected.to eq({ "test" => "was_missing", "missing" => "was_missing" })
      end

      it "writes to the cache" do
        expect(cache).to receive(:write).with(:example, { "test" => "was_missing", "missing" => "was_missing" })

        subject
      end
    end
  end
end
