# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Helpers::Caching do
  subject(:instance) { Class.new.include(described_class).new }

  describe "#present_cached" do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    let(:presenter) { API::Entities::Todo }

    let(:kwargs) do
      {
        with: presenter,
        project: project
      }
    end

    subject do
      instance.present_cached(presentable, **kwargs)
    end

    before do
      # We have to stub #body as it's a Grape method
      # unavailable in the module by itself
      expect(instance).to receive(:body) do |data|
        data
      end

      allow(instance).to receive(:current_user) { user }
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
end
