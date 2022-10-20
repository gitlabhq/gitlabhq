# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KeyPresenter do
  let(:presenter) { described_class.new(key) }

  describe '#humanized_error_message' do
    subject { presenter.humanized_error_message }

    before do
      key.valid?
    end

    context 'when public key is unsupported' do
      let(:key) { build(:key, key: 'a') }

      it 'returns the custom error message' do
        expect(subject).to eq('Key must be a <a target="_blank" rel="noopener noreferrer" ' \
          'href="/help/user/ssh#supported-ssh-key-types">supported SSH public key.</a>')
      end
    end

    context 'when key is expired' do
      let(:key) { build(:key, :expired) }

      it 'returns Active Record error message' do
        expect(subject).to eq('Key has expired')
      end
    end
  end
end
