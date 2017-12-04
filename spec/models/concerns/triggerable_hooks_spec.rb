require 'rails_helper'

RSpec.describe TriggerableHooks do
  before do
    class TestableHook < WebHook
      include TriggerableHooks
      triggerable_hooks only: [:push_hooks]
    end
  end

  describe 'scopes' do
    it 'defines a scope for each of the requested triggers' do
      expect(TestableHook).to respond_to :push_hooks
      expect(TestableHook).not_to respond_to :tag_push_hooks
    end
  end
end
