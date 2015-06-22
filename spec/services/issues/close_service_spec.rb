require 'spec_helper'

describe Issues::CloseService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:issue) { create(:issue, assignee: user2) }
  let(:project) { issue.project }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe :execute do
    context "valid params" do
      before do
        @issue = Issues::CloseService.new(project, user, {}).execute(issue)
      end

      it { expect(@issue).to be_valid }
      it { expect(@issue).to be_closed }

      it 'should send email to user2 about assign of new issue' do
        email = ActionMailer::Base.deliveries.last
        expect(email.to.first).to eq(user2.email)
        expect(email.subject).to include(issue.title)
      end

      it 'should create system note about issue reassign' do
        note = @issue.notes.last
        expect(note.note).to include "Status changed to closed"
      end
    end

    context "external issue tracker" do
      before do
        allow(project).to receive(:default_issues_tracker?).and_return(false)
        @issue = Issues::CloseService.new(project, user, {}).execute(issue)
      end

      it { expect(@issue).to be_valid }
      it { expect(@issue).to be_opened }
    end
  end
end
