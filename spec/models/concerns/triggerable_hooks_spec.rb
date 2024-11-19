# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TriggerableHooks, feature_category: :webhooks do
  before do
    stub_const('TestableHook', Class.new(WebHook))

    TestableHook.class_eval do
      include TriggerableHooks
      triggerable_hooks [:push_hooks]

      self.allow_legacy_sti_class = true

      scope :executable, -> { all }
    end
  end

  describe 'scopes' do
    it 'defines a scope for each of the requested triggers' do
      expect(TestableHook).to respond_to :push_hooks
      expect(TestableHook).not_to respond_to :tag_push_hooks
    end
  end

  describe '.hooks_for' do
    context 'the model has the required trigger scope' do
      it 'returns the record' do
        hook = TestableHook.create!(url: 'http://example.com', push_events: true)

        expect(TestableHook.hooks_for(:push_hooks)).to eq [hook]
      end
    end

    context 'the model does not have the required trigger scope' do
      it 'returns an empty relation' do
        TestableHook.create!(url: 'http://example.com')

        expect(TestableHook.hooks_for(:tag_push_hooks)).to eq []
      end
    end

    context 'the stock scope ".all" is accepted' do
      it 'returns the record' do
        hook = TestableHook.create!(url: 'http://example.com')

        expect(TestableHook.hooks_for(:all)).to eq [hook]
      end
    end
  end

  describe '.select_active' do
    it 'returns hooks that match the active filter' do
      TestableHook.create!(url: 'http://example1.com', push_events: true)
      TestableHook.create!(url: 'http://example.org', push_events: true)
      filter1 = double(:filter1)
      filter2 = double(:filter2)
      allow(ActiveHookFilter).to receive(:new).twice.and_return(filter1, filter2)
      expect(filter1).to receive(:matches?).and_return(true)
      expect(filter2).to receive(:matches?).and_return(false)

      hooks = TestableHook.push_hooks.order_id_asc
      expect(hooks.select_active(:push_hooks, {})).to eq [hooks.first]
    end

    it 'returns empty list if no hooks match the active filter' do
      TestableHook.create!(url: 'http://example1.com', push_events: true)
      filter = double(:filter)
      allow(ActiveHookFilter).to receive(:new).and_return(filter)
      expect(filter).to receive(:matches?).and_return(false)

      expect(TestableHook.push_hooks.select_active(:push_hooks, {})).to eq []
    end
  end
end
