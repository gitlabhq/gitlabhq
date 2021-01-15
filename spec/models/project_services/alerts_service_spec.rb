# frozen_string_literal: true

require 'spec_helper'

# AlertsService is stripped down to only required methods
# to avoid errors loading integration-related pages if
# records are present.
RSpec.describe AlertsService do
  let_it_be(:project) { create(:project) }
  subject(:service) { described_class.new(project: project) }

  it { is_expected.to be_valid }

  describe '#to_param' do
    subject { service.to_param }

    it { is_expected.to eq('alerts') }
  end

  describe '#supported_events' do
    subject { service.supported_events }

    it { is_expected.to be_empty }
  end

  describe '#save' do
    it 'prevents records from being created or updated' do
      expect(Gitlab::ProjectServiceLogger).to receive(:error).with(
        hash_including(message: 'Prevented attempt to save or update deprecated AlertsService')
      )

      expect(service.save).to be_falsey

      expect(service.errors.full_messages).to include(
        'Alerts endpoint is deprecated and should not be created or modified. Use HTTP Integrations instead.'
      )
    end
  end
end
