# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::AvatarCache, :clean_gitlab_redis_cache do
  def with(&blk)
    Gitlab::Redis::Cache.with(&blk)
  end

  def read(key, subkey)
    with do |redis|
      redis.hget(key, subkey)
    end
  end

  let(:thing) { double("thing", avatar_path: avatar_path) }
  let(:avatar_path) { "/avatars/my_fancy_avatar.png" }
  let(:key) { described_class.send(:email_key, "foo@bar.com") }

  let(:perform_fetch) do
    described_class.by_email("foo@bar.com", 20, 2, true) do
      thing.avatar_path
    end
  end

  describe "#by_email" do
    it "writes a new value into the cache" do
      expect(read(key, "20:2:true")).to eq(nil)

      perform_fetch

      expect(read(key, "20:2:true")).to eq(avatar_path)
    end

    it "finds the cached value and doesn't execute the block" do
      expect(thing).to receive(:avatar_path).once

      described_class.by_email("foo@bar.com", 20, 2, true) do
        thing.avatar_path
      end

      described_class.by_email("foo@bar.com", 20, 2, true) do
        thing.avatar_path
      end
    end

    it "finds the cached value in the request store and doesn't execute the block" do
      expect(thing).to receive(:avatar_path).once

      Gitlab::SafeRequestStore.ensure_request_store do
        described_class.by_email("foo@bar.com", 20, 2, true) do
          thing.avatar_path
        end

        described_class.by_email("foo@bar.com", 20, 2, true) do
          thing.avatar_path
        end

        expect(Gitlab::SafeRequestStore.read([key, "20:2:true"])).to eq(avatar_path)
      end
    end
  end

  describe "#delete_by_email" do
    subject { described_class.delete_by_email(*emails) }

    before do
      perform_fetch
    end

    context "no emails, somehow" do
      let(:emails) { [] }

      it { is_expected.to eq(0) }
    end

    context "single email" do
      let(:emails) { "foo@bar.com" }

      it "removes the email" do
        expect(read(key, "20:2:true")).to eq(avatar_path)

        expect(subject).to eq(1)

        expect(read(key, "20:2:true")).to eq(nil)
      end
    end

    context "multiple emails" do
      let(:emails) { ["foo@bar.com", "missing@baz.com"] }

      it "removes the emails it finds" do
        expect(read(key, "20:2:true")).to eq(avatar_path)

        expect(subject).to eq(1)

        expect(read(key, "20:2:true")).to eq(nil)
      end
    end

    context 'when deleting over 1000 emails' do
      it 'deletes in batches of 1000' do
        Gitlab::Redis::Cache.with do |redis|
          if Gitlab::Redis::ClusterUtil.cluster?(redis)
            expect(redis).to receive(:pipelined).at_least(2).and_call_original
          else
            expect(redis).to receive(:unlink).and_call_original
          end
        end

        described_class.delete_by_email(*(Array.new(1001) { |i| i }))
      end
    end
  end
end
