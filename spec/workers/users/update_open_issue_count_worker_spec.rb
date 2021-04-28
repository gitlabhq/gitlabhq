# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateOpenIssueCountWorker do
  let_it_be(:first_user) { create(:user) }
  let_it_be(:second_user) { create(:user) }

  describe '#perform' do
    let(:target_user_ids) { [first_user.id, second_user.id] }

    subject { described_class.new.perform(target_user_ids) }

    context 'when arguments are missing' do
      context 'when target_user_ids are missing' do
        context 'when nil' do
          let(:target_user_ids) { nil }

          it 'raises an error' do
            expect { subject }.to raise_error(ArgumentError, /No target user ID provided/)
          end
        end

        context 'when empty array' do
          let(:target_user_ids) { [] }

          it 'raises an error' do
            expect { subject }.to raise_error(ArgumentError, /No target user ID provided/)
          end
        end

        context 'when not an ID' do
          let(:target_user_ids) { "nonsense" }

          it 'raises an error' do
            expect { subject }.to raise_error(ArgumentError, /No valid target user ID provided/)
          end
        end
      end
    end

    context 'when successful' do
      let(:job_args) { [target_user_ids] }
      let(:fake_service1) { double }
      let(:fake_service2) { double }

      it 'calls the user update service' do
        expect(Users::UpdateAssignedOpenIssueCountService).to receive(:new).with(target_user: first_user).and_return(fake_service1)
        expect(Users::UpdateAssignedOpenIssueCountService).to receive(:new).with(target_user: second_user).and_return(fake_service2)
        expect(fake_service1).to receive(:execute)
        expect(fake_service2).to receive(:execute)

        subject
      end

      it_behaves_like 'an idempotent worker' do
        it 'recalculates' do
          subject

          expect(first_user.assigned_open_issues_count).to eq(0)
        end
      end
    end
  end
end
