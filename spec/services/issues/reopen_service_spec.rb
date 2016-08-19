require 'spec_helper'

describe Issues::ReopenService, services: true do
  let(:guest) { create(:user) }
  let(:issue) { create(:issue, :closed) }
  let(:project) { issue.project }

  before do
    project.team << [guest, :guest]
  end

  describe '#execute' do
    context 'current user is not authorized to reopen issue' do
      before do
        perform_enqueued_jobs do
          @issue = described_class.new(project, guest).execute(issue)
        end
      end

      it 'does not reopen the issue' do
        expect(@issue).to be_closed
      end
    end
  end
end
