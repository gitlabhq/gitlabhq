# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::ContainerRepository::Tags::Cache, :clean_gitlab_redis_cache do
  let_it_be(:dummy_tag_class) { Struct.new(:name, :created_at) }
  let_it_be(:repository) { create(:container_repository) }

  let(:tags) { create_tags(5) }
  let(:service) { described_class.new(repository) }

  shared_examples 'not interacting with redis' do
    it 'does not interact with redis' do
      expect(::Gitlab::Redis::Cache).not_to receive(:with)

      subject
    end
  end

  describe '#populate' do
    subject { service.populate(tags) }

    context 'with tags' do
      it 'gets values from redis' do
        expect(::Gitlab::Redis::Cache).to receive(:with).and_call_original

        expect(subject).to eq(0)

        tags.each { |t| expect(t.created_at).to eq(nil) }
      end

      context 'with cached values' do
        let(:cached_tags) { tags.first(2) }

        before do
          ::Gitlab::Redis::Cache.with do |redis|
            cached_tags.each do |tag|
              redis.set(cache_key(tag), rfc3339(10.days.ago))
            end
          end
        end

        it 'gets values from redis' do
          expect(::Gitlab::Redis::Cache).to receive(:with).and_call_original

          expect(subject).to eq(2)

          cached_tags.each { |t| expect(t.created_at).not_to eq(nil) }
          (tags - cached_tags).each { |t| expect(t.created_at).to eq(nil) }
        end
      end
    end

    context 'with no tags' do
      let(:tags) { [] }

      it_behaves_like 'not interacting with redis'
    end
  end

  describe '#insert' do
    let(:max_ttl) { 90.days }

    subject { service.insert(tags, max_ttl) }

    context 'with tags' do
      let(:tag) { tags.first }
      let(:ttl) { 90.days - 3.days }

      before do
        travel_to(Time.zone.local(2021, 9, 2, 12, 0, 0))

        tag.created_at = DateTime.rfc3339(3.days.ago.rfc3339)
      end

      after do
        travel_back
      end

      it 'inserts values in redis' do
        ::Gitlab::Redis::Cache.with do |redis|
          expect(redis).to receive(:pipelined).and_call_original

          expect_next_instance_of(Redis::PipelinedConnection) do |pipeline|
            expect(pipeline)
              .to receive(:set)
                    .with(cache_key(tag), rfc3339(tag.created_at), ex: ttl.to_i)
                    .and_call_original
          end
        end

        subject
      end

      context 'with some of them already cached' do
        let(:tag) { tags.first }

        before do
          ::Gitlab::Redis::Cache.with do |redis|
            redis.set(cache_key(tag), rfc3339(10.days.ago))
          end
          service.populate(tags)
        end

        it_behaves_like 'not interacting with redis'
      end
    end

    context 'with no tags' do
      let(:tags) { [] }

      it_behaves_like 'not interacting with redis'
    end

    context 'with no expires_in' do
      let(:max_ttl) { nil }

      it_behaves_like 'not interacting with redis'
    end
  end

  def create_tags(size)
    Array.new(size) do |i|
      dummy_tag_class.new("Tag #{i}", nil)
    end
  end

  def cache_key(tag)
    "container_repository:{#{repository.id}}:tag:#{tag.name}:created_at"
  end

  def rfc3339(date_time)
    # DateTime rfc3339 is different ActiveSupport::TimeWithZone rfc3339
    # The caching will use DateTime rfc3339
    DateTime.rfc3339(date_time.rfc3339).rfc3339
  end
end
