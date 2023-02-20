# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Helpers::Caching, :use_clean_rails_redis_caching do
  subject(:instance) { Class.new.include(described_class, Grape::DSL::Headers).new }

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:presenter) { API::Entities::Todo }

  let(:return_value) do
    {
      foo: "bar"
    }
  end

  let(:kwargs) do
    {
      expires_in: 1.minute
    }
  end

  before do
    # We have to stub #body as it's a Grape method
    # unavailable in the module by itself
    allow(instance).to receive(:body) do |data|
      data
    end

    allow(instance).to receive(:current_user) { user }
  end

  describe "#present_cached" do
    let(:method) { :present_cached }
    let(:kwargs) do
      {
        with: presenter,
        project: project
      }
    end

    subject do
      instance.public_send(method, presentable, **kwargs)
    end

    context 'single object' do
      let_it_be(:presentable) { create(:todo, project: project) }
      let(:expected_cache_key_prefix) { 'API::Entities::Todo' }

      it_behaves_like 'object cache helper'
    end

    context 'collection of objects' do
      let_it_be(:presentable) { Array.new(5).map { create(:todo, project: project) } }
      let(:expected_cache_key_prefix) { 'API::Entities::Todo' }

      it_behaves_like 'collection cache helper'
    end
  end

  describe "#cache_action" do
    def perform
      instance.cache_action(cache_key, **kwargs) do
        expensive_thing.do_very_expensive_action
      end
    end

    subject { perform }

    let(:expensive_thing) { double(do_very_expensive_action: return_value) }
    let(:cache_key) do
      [user, :foo]
    end

    it { is_expected.to be_a(Gitlab::Json::PrecompiledJson) }

    it "represents the correct data" do
      expect(subject.to_s).to eq(Gitlab::Json.dump(return_value).to_s)
    end

    it "only calls the expensive action once" do
      expected_kwargs = described_class::DEFAULT_CACHE_OPTIONS.merge(kwargs)

      expect(expensive_thing).to receive(:do_very_expensive_action).once
      expect(instance.cache).to receive(:fetch).with(cache_key, **expected_kwargs).exactly(5).times.and_call_original

      5.times { perform }
    end

    it "handles nested cache calls" do
      nested_call = instance.cache_action(cache_key, **kwargs) do
        instance.cache_action([:nested], **kwargs) do
          expensive_thing.do_very_expensive_action
        end
      end

      expect(nested_call.to_s).to eq(subject.to_s)
    end

    context 'Cache versioning' do
      it 'returns cache based on version parameter' do
        result_1 = instance.cache_action(cache_key, **kwargs.merge(version: 1)) { 'Cache 1' }
        result_2 = instance.cache_action(cache_key, **kwargs.merge(version: 2)) { 'Cache 2' }

        expect(result_1.to_s).to eq('Cache 1'.to_json)
        expect(result_2.to_s).to eq('Cache 2'.to_json)
      end
    end

    context 'Cache for pagination headers' do
      described_class::PAGINATION_HEADERS.each do |pagination_header|
        context pagination_header do
          before do
            instance.header(pagination_header, 100)
          end

          it 'stores and recovers pagination headers from cache' do
            expect { perform }.not_to change { instance.header[pagination_header] }

            instance.header.delete(pagination_header)

            expect { perform }.to change { instance.header[pagination_header] }.from(nil).to(100)
          end

          it 'prefers headers from request than from cache' do
            expect { perform }.not_to change { instance.header[pagination_header] }

            instance.header(pagination_header, 50)

            expect { perform }.not_to change { instance.header[pagination_header] }.from(50)
          end
        end
      end
    end
  end

  describe "#cache_action_if" do
    subject do
      instance.cache_action_if(conditional, cache_key, **kwargs) do
        return_value
      end
    end

    let(:cache_key) do
      [user, :conditional_if]
    end

    context "conditional is truthy" do
      let(:conditional) { "truthy thing" }

      it { is_expected.to be_a(Gitlab::Json::PrecompiledJson) }

      it "caches the block" do
        expect(instance).to receive(:cache_action).with(cache_key, **kwargs)

        subject
      end
    end

    context "conditional is falsey" do
      let(:conditional) { false }

      it { is_expected.to eq(return_value) }

      it "doesn't cache the block" do
        expect(instance).not_to receive(:cache_action).with(cache_key, **kwargs)

        subject
      end
    end
  end

  describe "#cache_action_unless" do
    subject do
      instance.cache_action_unless(conditional, cache_key, **kwargs) do
        return_value
      end
    end

    let(:cache_key) do
      [user, :conditional_unless]
    end

    context "conditional is truthy" do
      let(:conditional) { "truthy thing" }

      it { is_expected.to eq(return_value) }

      it "doesn't cache the block" do
        expect(instance).not_to receive(:cache_action).with(cache_key, **kwargs)

        subject
      end
    end

    context "conditional is falsey" do
      let(:conditional) { false }

      it { is_expected.to be_a(Gitlab::Json::PrecompiledJson) }

      it "caches the block" do
        expect(instance).to receive(:cache_action).with(cache_key, **kwargs)

        subject
      end
    end
  end
end
