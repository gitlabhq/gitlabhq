require 'rails_helper'

RSpec.describe TriggerableHooks do
  before do
    class TestableHook < WebHook
      include TriggerableHooks
      triggerable_hooks [:push_hooks]
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
end
