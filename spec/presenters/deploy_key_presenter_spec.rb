# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeyPresenter do
  let(:presenter) { described_class.new(deploy_key) }

  describe '#humanized_error_message' do
    subject { presenter.humanized_error_message }

    before do
      deploy_key.valid?
    end

    context 'when public key is unsupported' do
      let(:deploy_key) { build(:deploy_key, key: 'a') }

      it 'returns the custom error message' do
        expect(subject).to eq('Deploy key must be a <a target="_blank" rel="noopener noreferrer" ' \
          'href="/help/user/ssh#supported-ssh-key-types">supported SSH public key.</a>')
      end
    end
  end
end
