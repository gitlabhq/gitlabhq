# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegration do
  let_it_be(:project) { create(:project) }

  subject(:integration) { build(:alert_management_http_integration) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:endpoint_identifier) }
    it { is_expected.to validate_length_of(:endpoint_identifier).is_at_most(255) }

    context 'when active' do
      # Using `create` instead of `build` the integration so `token` is set.
      # Uniqueness spec saves integration with `validate: false` otherwise.
      subject { create(:alert_management_http_integration) }

      it { is_expected.to validate_uniqueness_of(:endpoint_identifier).scoped_to(:project_id, :active) }
    end

    context 'when inactive' do
      subject { create(:alert_management_http_integration, :inactive) }

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
        before do
          integration.valid?
        end

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
end
