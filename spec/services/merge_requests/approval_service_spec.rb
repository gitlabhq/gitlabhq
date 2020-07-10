# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ApprovalService do
  describe '#execute' do
    let(:user)          { create(:user) }
    let(:merge_request) { create(:merge_request) }
    let(:project)       { merge_request.project }
    let!(:todo)         { create(:todo, user: user, project: project, target: merge_request) }

    subject(:service) { described_class.new(project, user) }

    before do
      project.add_developer(user)
    end

    context 'with invalid approval' do
      before do
        allow(merge_request.approvals).to receive(:new).and_return(double(save: false))
      end

      it 'does not create an approval note' do
        expect(SystemNoteService).not_to receive(:approve_mr)

        service.execute(merge_request)
      end

      it 'does not mark pending todos as done' do
        service.execute(merge_request)

        expect(todo.reload).to be_pending
      end
    end

    context 'with valid approval' do
      it 'creates an approval note and marks pending todos as done' do
        expect(SystemNoteService).to receive(:approve_mr).with(merge_request, user)
        expect(merge_request.approvals).to receive(:reset)

        service.execute(merge_request)

        expect(todo.reload).to be_done
      end

      it 'creates approve MR event' do
        expect_next_instance_of(EventCreateService) do |instance|
          expect(instance).to receive(:approve_mr)
            .with(merge_request, user)
        end

        service.execute(merge_request)
      end

      context 'with remaining approvals' do
        it 'fires an approval webhook' do
          expect(service).to receive(:execute_hooks).with(merge_request, 'approved')

          service.execute(merge_request)
        end
      end
    end

    context 'user cannot update the merge request' do
      before do
        project.add_guest(user)
      end

      it 'does not update approvals' do
        expect { service.execute(merge_request) }.not_to change { merge_request.approvals.size }
      end
    end
  end
end
