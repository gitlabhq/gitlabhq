# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ActionCable::RequestStoreCallbacks do
  describe '.wrapper' do
    it 'enables RequestStore in the inner block' do
      expect(RequestStore.active?).to be(false)

      described_class.wrapper.call(
        nil,
        -> do
          expect(RequestStore.active?).to be(true)
        end
      )

      expect(RequestStore.active?).to be(false)
    end
  end
end
