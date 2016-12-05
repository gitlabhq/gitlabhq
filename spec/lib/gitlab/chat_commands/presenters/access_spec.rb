require 'spec_helper'

describe Gitlab::ChatCommands::Presenters::Access do
  describe '#access_denied' do
    subject { described_class.new(nil).access_denied }

    it { is_expected.to have_key(:text) }
    it { is_expected.to have_key(:status) }
    it { is_expected.to have_key(:response_type) }
    it { is_expected.not_to have_key(:attachments) }

    it 'tells the user the action is not allowed' do
      expect(subject[:text]).to start_with("Whoops! This action is not allowed")
      expect(subject[:response_type]).to be(:ephemeral)
    end
  end
end
