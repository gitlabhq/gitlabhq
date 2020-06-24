# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::Deploy do
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

  describe '#action_not_found' do
    subject { described_class.new(nil).action_not_found }

    it { is_expected.to have_key(:text) }
    it { is_expected.to have_key(:response_type) }
    it { is_expected.to have_key(:status) }
    it { is_expected.not_to have_key(:attachments) }

    it 'tells the user there is no action' do
      expect(subject[:response_type]).to be(:ephemeral)
      expect(subject[:text]).to eq "Couldn't find a deployment manual action."
    end
  end
end
