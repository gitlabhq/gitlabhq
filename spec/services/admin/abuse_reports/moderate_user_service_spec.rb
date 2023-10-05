# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReports::ModerateUserService, feature_category: :instance_resiliency do
  let_it_be_with_reload(:abuse_report) { create(:abuse_report) }
  let_it_be_with_reload(:similar_abuse_report) do
    create(:abuse_report, user: abuse_report.user, category: abuse_report.category)
  end

  let(:action) { 'ban_user' }
  let(:close) { true }
  let(:reason) { 'spam' }
  let(:params) { { user_action: action, close: close, reason: reason, comment: 'obvious spam' } }
  let_it_be(:admin) { create(:admin) }

  let(:service) { described_class.new(abuse_report, admin, params) }

  describe '#execute', :enable_admin_mode do
    subject { service.execute }

    shared_examples 'returns an error response' do |error|
      it 'returns an error response' do
        expect(subject.status).to eq :error
        expect(subject.message).to eq error
      end
    end

    shared_examples 'closes the report' do
      it 'closes the report' do
        expect { subject }.to change { abuse_report.closed? }.from(false).to(true)
      end

      context 'when similar open reports for the user exist' do
        it 'closes the similar report' do
          expect { subject }.to change { similar_abuse_report.reload.closed? }.from(false).to(true)
        end
      end
    end

    shared_examples 'does not close the report' do
      it 'does not close the report' do
        subject
        expect(abuse_report.closed?).to be(false)
      end

      context 'when similar open reports for the user exist' do
        it 'does not close the similar report' do
          subject
          expect(similar_abuse_report.reload.closed?).to be(false)
        end
      end
    end

    shared_examples 'does not record an event' do
      it 'does not record an event' do
        expect { subject }.not_to change { abuse_report.events.count }
      end
    end

    shared_examples 'records an event' do |action:|
      it 'records the event', :aggregate_failures do
        expect { subject }.to change { abuse_report.events.count }.by(1)

        expect(abuse_report.events.last).to have_attributes(
          action: action,
          user: admin,
          reason: reason,
          comment: params[:comment]
        )
      end

      it 'returns the event success message' do
        expect(subject.message).to eq(abuse_report.events.last.success_message)
      end
    end

    context 'when invalid parameters are given' do
      describe 'invalid user' do
        describe 'when no user is given' do
          let_it_be(:admin) { nil }

          it_behaves_like 'returns an error response', 'Admin is required'
        end

        describe 'when given user is no admin' do
          let_it_be(:admin) { create(:user) }

          it_behaves_like 'returns an error response', 'Admin is required'
        end
      end

      describe 'invalid action' do
        describe 'when no action is given' do
          let(:action) { '' }
          let(:close) { 'false' }

          it_behaves_like 'returns an error response', 'Action is required'
        end

        describe 'when unknown action is given' do
          let(:action) { 'unknown' }
          let(:close) { 'false' }

          it_behaves_like 'returns an error response', 'Action is required'
        end
      end

      describe 'invalid reason' do
        let(:reason) { '' }

        it 'sets the reason to `other`' do
          subject

          expect(abuse_report.events.last).to have_attributes(reason: 'other')
        end
      end
    end

    describe 'when banning the user' do
      it 'calls the Users::BanService' do
        expect_next_instance_of(Users::BanService, admin) do |service|
          expect(service).to receive(:execute).with(abuse_report.user).and_return(status: :success)
        end

        subject
      end

      context 'when closing the report' do
        it_behaves_like 'closes the report'
        it_behaves_like 'records an event', action: 'ban_user_and_close_report'
      end

      context 'when not closing the report' do
        let(:close) { 'false' }

        it_behaves_like 'does not close the report'
        it_behaves_like 'records an event', action: 'ban_user'
      end

      context 'when banning the user fails' do
        before do
          allow_next_instance_of(Users::BanService, admin) do |service|
            allow(service).to receive(:execute).with(abuse_report.user)
              .and_return(status: :error, message: 'Banning the user failed')
          end
        end

        it_behaves_like 'returns an error response', 'Banning the user failed'
        it_behaves_like 'does not close the report'
        it_behaves_like 'does not record an event'
      end
    end

    describe 'when blocking the user' do
      let(:action) { 'block_user' }

      it 'calls the Users::BlockService' do
        expect_next_instance_of(Users::BlockService, admin) do |service|
          expect(service).to receive(:execute).with(abuse_report.user).and_return(status: :success)
        end

        subject
      end

      context 'when closing the report' do
        it_behaves_like 'closes the report'
        it_behaves_like 'records an event', action: 'block_user_and_close_report'
      end

      context 'when not closing the report' do
        let(:close) { 'false' }

        it_behaves_like 'does not close the report'
        it_behaves_like 'records an event', action: 'block_user'
      end

      context 'when blocking the user fails' do
        before do
          allow_next_instance_of(Users::BlockService, admin) do |service|
            allow(service).to receive(:execute).with(abuse_report.user)
              .and_return(status: :error, message: 'Blocking the user failed')
          end
        end

        it_behaves_like 'returns an error response', 'Blocking the user failed'
        it_behaves_like 'does not close the report'
        it_behaves_like 'does not record an event'
      end
    end

    describe 'when deleting the user' do
      let(:action) { 'delete_user' }

      it 'calls the delete_async method' do
        expect(abuse_report.user).to receive(:delete_async).with(deleted_by: admin)
        subject
      end

      context 'when closing the report' do
        it_behaves_like 'closes the report'
        it_behaves_like 'records an event', action: 'delete_user_and_close_report'
      end

      context 'when not closing the report' do
        let(:close) { 'false' }

        it_behaves_like 'does not close the report'
        it_behaves_like 'records an event', action: 'delete_user'
      end
    end

    describe 'when trusting the user' do
      let(:action) { 'trust_user' }

      it 'calls the Users::TrustService method' do
        expect_next_instance_of(Users::TrustService, admin) do |service|
          expect(service).to receive(:execute).with(abuse_report.user).and_return(status: :success)
        end

        subject
      end

      context 'when not closing the report' do
        let(:close) { false }

        it_behaves_like 'does not close the report'
        it_behaves_like 'records an event', action: 'trust_user'
      end

      context 'when closing the report' do
        it_behaves_like 'closes the report'
        it_behaves_like 'records an event', action: 'trust_user_and_close_report'
      end

      context 'when trusting the user fails' do
        before do
          allow_next_instance_of(Users::TrustService) do |service|
            allow(service).to receive(:execute).with(abuse_report.user)
             .and_return(status: :error, message: 'Trusting the user failed')
          end
        end

        it_behaves_like 'returns an error response', 'Trusting the user failed'
        it_behaves_like 'does not close the report'
        it_behaves_like 'does not record an event'
      end
    end

    describe 'when only closing the report' do
      let(:action) { '' }

      it_behaves_like 'closes the report'
      it_behaves_like 'records an event', action: 'close_report'

      context 'when report is already closed' do
        before do
          abuse_report.closed!
        end

        it_behaves_like 'returns an error response', 'Report already closed'
        it_behaves_like 'does not record an event'
      end
    end
  end
end
