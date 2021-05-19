# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Helpers::Caching, :use_clean_rails_redis_caching do
  subject(:instance) { Class.new.include(described_class).new }

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
    subject do
      instance.present_cached(presentable, **kwargs)
    end

    let(:kwargs) do
      {
        with: presenter,
        project: project
      }
    end

    context "single object" do
      let_it_be(:presentable) { create(:todo, project: project) }

      it { is_expected.to be_a(Gitlab::Json::PrecompiledJson) }

      it "uses the presenter" do
        expect(presenter).to receive(:represent).with(presentable, project: project)

        subject
      end

      it "is valid JSON" do
        parsed = Gitlab::Json.parse(subject.to_s)

        expect(parsed).to be_a(Hash)
        expect(parsed["id"]).to eq(presentable.id)
      end

      it "fetches from the cache" do
        expect(instance.cache).to receive(:fetch).with("#{presentable.cache_key}:#{user.cache_key}", expires_in: described_class::DEFAULT_EXPIRY).once

        subject
      end

      context "when a cache context is supplied" do
        before do
          kwargs[:cache_context] = -> (todo) { todo.project.cache_key }
        end

        it "uses the context to augment the cache key" do
          expect(instance.cache).to receive(:fetch).with("#{presentable.cache_key}:#{project.cache_key}", expires_in: described_class::DEFAULT_EXPIRY).once

          subject
        end
      end

      context "when expires_in is supplied" do
        it "sets the expiry when accessing the cache" do
          kwargs[:expires_in] = 7.days

          expect(instance.cache).to receive(:fetch).with("#{presentable.cache_key}:#{user.cache_key}", expires_in: 7.days).once

          subject
        end
      end
    end

    context "for a collection of objects" do
      let_it_be(:presentable) { Array.new(5).map { create(:todo, project: project) } }

      it { is_expected.to be_an(Gitlab::Json::PrecompiledJson) }

      it "uses the presenter" do
        presentable.each do |todo|
          expect(presenter).to receive(:represent).with(todo, project: project)
        end

        subject
      end

      it "is valid JSON" do
        parsed = Gitlab::Json.parse(subject.to_s)

        expect(parsed).to be_an(Array)

        presentable.each_with_index do |todo, i|
          expect(parsed[i]["id"]).to eq(todo.id)
        end
      end

      it "fetches from the cache" do
        keys = presentable.map { |todo| "#{todo.cache_key}:#{user.cache_key}" }

        expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: described_class::DEFAULT_EXPIRY).once.and_call_original

        subject
      end

      context "when a cache context is supplied" do
        before do
          kwargs[:cache_context] = -> (todo) { todo.project.cache_key }
        end

        it "uses the context to augment the cache key" do
          keys = presentable.map { |todo| "#{todo.cache_key}:#{project.cache_key}" }

          expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: described_class::DEFAULT_EXPIRY).once.and_call_original

          subject
        end
      end

      context "expires_in is supplied" do
        it "sets the expiry when accessing the cache" do
          keys = presentable.map { |todo| "#{todo.cache_key}:#{user.cache_key}" }
          kwargs[:expires_in] = 7.days

          expect(instance.cache).to receive(:fetch_multi).with(*keys, expires_in: 7.days).once.and_call_original

          subject
        end
      end
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
