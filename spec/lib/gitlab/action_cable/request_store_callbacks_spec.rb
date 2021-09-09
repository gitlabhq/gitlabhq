# frozen_string_literal: true

RSpec.describe Gitlab::ActionCable::RequestStoreCallbacks do
  describe '.wrapper' do
    it 'enables RequestStore in the inner block' do
      expect(RequestStore.active?).to eq(false)

      described_class.wrapper.call(
        nil,
        lambda do
          expect(RequestStore.active?).to eq(true)
        end
      )

      expect(RequestStore.active?).to eq(false)
    end
  end
end
