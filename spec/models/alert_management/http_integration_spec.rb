# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegration do
  include ::Gitlab::Routing.url_helpers

  let_it_be(:project) { create(:project) }

  subject(:integration) { build(:alert_management_http_integration) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }

    context 'when active' do
      # Using `create` instead of `build` the integration so `token` is set.
      # Uniqueness spec saves integration with `validate: false` otherwise.
      subject { create(:alert_management_http_integration, :legacy) }

      it { is_expected.to validate_uniqueness_of(:endpoint_identifier).scoped_to(:project_id, :active) }
    end

    context 'when inactive' do
      subject { create(:alert_management_http_integration, :legacy, :inactive) }

      it { is_expected.not_to validate_uniqueness_of(:endpoint_identifier).scoped_to(:project_id, :active) }
    end
  end

  describe '#token' do
    subject { integration.token }

    shared_context 'assign token' do |token|
      let!(:previous_token) { integration.token }

      before do
        integration.token = token
        integration.valid?
      end
    end

    shared_examples 'valid token' do
      it { is_expected.to match(/\A\h{32}\z/) }
    end

    context 'when unsaved' do
      context 'when unassigned' do
        it_behaves_like 'valid token'
      end

      context 'when assigned' do
        include_context 'assign token', 'random_token'

        it_behaves_like 'valid token'
        it { is_expected.not_to eq('random_token') }
      end
    end

    context 'when persisted' do
      before do
        integration.save!
        integration.reload
      end

      it_behaves_like 'valid token'

      context 'when resetting' do
        include_context 'assign token', ''

        it_behaves_like 'valid token'
        it { is_expected.not_to eq(previous_token) }
      end

      context 'when reassigning' do
        include_context 'assign token', 'random_token'

        it_behaves_like 'valid token'
        it { is_expected.to eq(previous_token) }
      end
    end
  end

  describe '#endpoint_identifier' do
    subject { integration.endpoint_identifier }

    context 'when defined on initialize' do
      let(:integration) { described_class.new }

      it { is_expected.to match(/\A\h{16}\z/) }
    end

    context 'when included in initialization args' do
      let(:integration) { described_class.new(endpoint_identifier: 'legacy') }

      it { is_expected.to eq('legacy') }
    end

    context 'when reassigning' do
      let(:integration) { create(:alert_management_http_integration) }
      let!(:starting_identifier) { subject }

      it 'does not allow reassignment' do
        integration.endpoint_identifier = 'newValidId'
        integration.save!

        expect(integration.reload.endpoint_identifier).to eq(starting_identifier)
      end
    end
  end

  describe '#url' do
    subject { integration.url }

    it do
      is_expected.to eq(
        project_alert_http_integration_url(
          integration.project,
          'datadog',
          integration.endpoint_identifier,
          format: :json
        )
      )
    end

    context 'when name is not defined' do
      let(:integration) { described_class.new(project: project) }

      it do
        is_expected.to eq(
          project_alert_http_integration_url(
            integration.project,
            'http-endpoint',
            integration.endpoint_identifier,
            format: :json
          )
        )
      end
    end

    context 'for a legacy integration' do
      let(:integration) { build(:alert_management_http_integration, :legacy) }

      it do
        is_expected.to eq(
          project_alerts_notify_url(
            integration.project,
            format: :json
          )
        )
      end
    end
  end
end
