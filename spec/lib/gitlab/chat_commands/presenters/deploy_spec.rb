require 'spec_helper'

describe Gitlab::ChatCommands::Presenters::Deploy do
  let(:build) { create(:ci_build) }

  describe '#present' do
    subject { described_class.new(build).present('staging', 'prod') }

    it { is_expected.to have_key(:text) }
    it { is_expected.to have_key(:response_type) }
    it { is_expected.to have_key(:status) }
    it { is_expected.not_to have_key(:attachments) }

    it 'messages the channel of the deploy' do
      expect(subject[:response_type]).to be(:in_channel)
      expect(subject[:text]).to start_with("Deployment started from staging to prod")
    end
  end

  describe '#no_actions' do
    subject { described_class.new(nil).no_actions }

    it { is_expected.to have_key(:text) }
    it { is_expected.to have_key(:response_type) }
    it { is_expected.to have_key(:status) }
    it { is_expected.not_to have_key(:attachments) }

    it 'tells the user there is no action' do
      expect(subject[:response_type]).to be(:ephemeral)
      expect(subject[:text]).to eq("No action found to be executed")
    end
  end

  describe '#too_many_actions' do
    subject { described_class.new([]).too_many_actions }

    it { is_expected.to have_key(:text) }
    it { is_expected.to have_key(:response_type) }
    it { is_expected.to have_key(:status) }
    it { is_expected.not_to have_key(:attachments) }

    it 'tells the user there is no action' do
      expect(subject[:response_type]).to be(:ephemeral)
      expect(subject[:text]).to eq("Too many actions defined")
    end
  end
end
