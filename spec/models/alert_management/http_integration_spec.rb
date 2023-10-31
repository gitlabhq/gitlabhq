# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegration, feature_category: :incident_management do
  include ::Gitlab::Routing.url_helpers

  let_it_be(:project) { create(:project) }

  subject(:integration) { build(:alert_management_http_integration, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'default values' do
    it { expect(described_class.new.endpoint_identifier).to be_present }
    it { expect(described_class.new(endpoint_identifier: 'test').endpoint_identifier).to eq('test') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:type_identifier) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }

    context 'when active' do
      # Using `create` instead of `build` the integration so `token` is set.
      # Uniqueness spec saves integration with `validate: false` otherwise.
      subject { create(:alert_management_http_integration, :legacy) }

      it { is_expected.to validate_uniqueness_of(:endpoint_identifier).scoped_to(:project_id) }
    end

    context 'when inactive' do
      subject { create(:alert_management_http_integration, :legacy, :inactive) }

      it { is_expected.to validate_uniqueness_of(:endpoint_identifier).scoped_to(:project_id) }
    end

    context 'payload_attribute_mapping' do
      subject { build(:alert_management_http_integration, payload_attribute_mapping: attribute_mapping) }

      context 'with valid JSON schema' do
        let(:attribute_mapping) do
          {
            title: { path: %w[a b c], type: 'string', label: 'Title' },
            description: { path: %w[a], type: 'string' }
          }
        end

        it { is_expected.to be_valid }
      end

      context 'with invalid JSON schema' do
        shared_examples 'is invalid record' do
          it do
            expect(subject).to be_invalid
            expect(subject.errors.messages[:payload_attribute_mapping]).to eq(['must be a valid json schema'])
          end
        end

        context 'when property is not an object' do
          let(:attribute_mapping) do
            { title: 'That is not a valid schema' }
          end

          it_behaves_like 'is invalid record'
        end

        context 'when property missing required attributes' do
          let(:attribute_mapping) do
            { title: { type: 'string' } }
          end

          it_behaves_like 'is invalid record'
        end

        context 'when property has extra attributes' do
          let(:attribute_mapping) do
            { title: { path: %w[a b c], type: 'string', extra: 'property' } }
          end

          it_behaves_like 'is invalid record'
        end
      end
    end
  end

  describe 'scopes' do
    let_it_be(:integration_1) { create(:alert_management_http_integration) }
    let_it_be(:integration_2) { create(:alert_management_http_integration, :inactive, project: project) }
    let_it_be(:integration_3) { create(:alert_management_prometheus_integration, project: project) }
    let_it_be(:integration_4) { create(:alert_management_http_integration, :legacy, :inactive) }

    describe '.for_endpoint_identifier' do
      let(:identifier) { integration_1.endpoint_identifier }

      subject { described_class.for_endpoint_identifier(identifier) }

      it { is_expected.to contain_exactly(integration_1) }
    end

    describe '.for_type' do
      let(:type) { :prometheus }

      subject { described_class.for_type(type) }

      it { is_expected.to contain_exactly(integration_3) }
    end

    describe '.for_project' do
      let(:project) { integration_2.project }

      subject { described_class.for_project(project) }

      it { is_expected.to contain_exactly(integration_2, integration_3) }

      context 'with project_ids array' do
        let(:project) { [integration_1.project_id] }

        it { is_expected.to contain_exactly(integration_1) }
      end
    end

    describe '.active' do
      subject { described_class.active }

      it { is_expected.to contain_exactly(integration_1, integration_3) }
    end

    describe '.ordered_by_type_and_id' do
      before do
        # Rearrange cache by saving to avoid false-positives
        integration_2.touch
      end

      subject { described_class.ordered_by_type_and_id }

      it { is_expected.to eq([integration_1, integration_2, integration_4, integration_3]) }
    end
  end

  describe 'before validation' do
    describe '#ensure_payload_example_not_nil' do
      subject(:integration) { build(:alert_management_http_integration, payload_example: payload_example) }

      context 'when the payload_example is nil' do
        let(:payload_example) { nil }

        it 'sets the payload_example to empty JSON' do
          integration.valid?

          expect(integration.payload_example).to eq({})
        end
      end

      context 'when the payload_example is not nil' do
        let(:payload_example) { { 'key' => 'value' } }

        it 'sets the payload_example to specified value' do
          integration.valid?

          expect(integration.payload_example).to eq(payload_example)
        end
      end
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
      let(:required_args) { { project: project, name: 'Name' } }

      AlertManagement::HttpIntegration::LEGACY_IDENTIFIERS.each do |identifier|
        context "for endpoint identifier \"#{identifier}\"" do
          let(:integration) { described_class.new(**required_args, endpoint_identifier: identifier) }

          it { is_expected.to eq(identifier) }
          specify { expect(integration).to be_valid }
        end
      end
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

    context 'for a prometheus integration' do
      let(:integration) { build(:alert_management_prometheus_integration) }

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

      context 'for a legacy integration' do
        let(:integration) { build(:alert_management_prometheus_integration, :legacy) }

        it do
          is_expected.to eq(
            notify_project_prometheus_alerts_url(
              integration.project,
              format: :json
            )
          )
        end
      end
    end
  end
end
