# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReports::UpdateService, feature_category: :instance_resiliency do
  let_it_be(:current_user) { create(:admin) }
  let_it_be(:abuse_report) { create(:abuse_report) }
  let_it_be(:label) { create(:abuse_report_label) }

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

      describe 'invalid label_ids' do
        let(:params) { { label_ids: ['invalid_global_id', non_existing_record_id] } }

        it 'does not update the abuse report' do
          expect { subject }.not_to change { abuse_report.labels }
        end

        it { is_expected.to be_success }
      end
    end

    describe 'with valid parameters' do
      context 'when label_ids is empty' do
        let(:params) { { label_ids: [] } }

        context 'when abuse report has existing labels' do
          before do
            abuse_report.labels = [label]
          end

          it 'clears the abuse report labels' do
            expect { subject }.to change { abuse_report.labels.count }.from(1).to(0)
          end

          it { is_expected.to be_success }
        end

        context 'when abuse report has no existing labels' do
          it 'does not update the abuse report' do
            expect { subject }.not_to change { abuse_report.labels }
          end

          it { is_expected.to be_success }
        end
      end

      context 'when label_ids is not empty' do
        let(:params) { { label_ids: [Gitlab::GlobalId.build(label, id: label.id).to_s] } }

        it 'updates the abuse report' do
          expect { subject }.to change { abuse_report.label_ids }.from([]).to([label.id])
        end

        it { is_expected.to be_success }
      end
    end
  end
end
