# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReports::UpdateService, feature_category: :instance_resiliency do
  let_it_be(:current_user) { create(:admin) }
  let_it_be(:abuse_report) { create(:abuse_report) }

  let(:params) { {} }
  let(:service) { described_class.new(abuse_report, current_user, params) }

  describe '#execute', :enable_admin_mode do
    subject { service.execute }

    shared_examples 'returns an error response' do |error|
      it 'returns an error response' do
        expect(subject).to be_error
        expect(subject.message).to eq error
      end
    end

    context 'with invalid parameters' do
      describe 'invalid user' do
        describe 'when no user is given' do
          let_it_be(:current_user) { nil }

          it_behaves_like 'returns an error response', 'Admin is required'
        end

        describe 'when given user is not an admin' do
          let_it_be(:current_user) { create(:user) }

          it_behaves_like 'returns an error response', 'Admin is required'
        end
      end
    end

    describe 'with valid parameters' do
      it { is_expected.to be_success }
    end
  end
end
