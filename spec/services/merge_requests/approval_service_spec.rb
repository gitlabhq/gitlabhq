require 'rails_helper'

describe MergeRequests::ApprovalService, services: true do
  describe '#execute' do
    let(:user)          { build_stubbed(:user) }
    let(:project)       { build_stubbed(:empty_project) }
    let(:merge_request) { build_stubbed(:merge_request) }

    context 'with invalid approval' do
      it 'does not create an approval note' do
        allow(merge_request.approvals).
          to receive(:new).and_return(double(save: false))
        service = described_class.new(double, double)

        expect(SystemNoteService).not_to receive(:approve_mr)

        service.execute(merge_request)
      end
    end

    context 'with valid approval' do
      it 'creates an approval note' do
        service = described_class.new(project, user)

        expect(SystemNoteService).to receive(:approve_mr).with(merge_request, user)

        service.execute(merge_request)
      end

      context 'with remaining approvals' do
        it 'does not fire a webhook' do
          expect(merge_request).to receive(:approvals_left).and_return(5)

          service = described_class.new(project, user)
          expect(service).not_to receive(:execute_hooks)

          service.execute(merge_request)
        end
      end

      context 'with required approvals' do
        it 'fires a webhook' do
          expect(merge_request).to receive(:approvals_left).and_return(0)

          service = described_class.new(project, user)
          expect(service).to receive(:execute_hooks).with(merge_request, 'approved')

          service.execute(merge_request)
        end
      end
    end
  end
end
