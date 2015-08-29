require 'spec_helper'

describe EmailsOnPushWorker do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:data) { Gitlab::PushDataBuilder.build_sample(project, user) }

  subject { EmailsOnPushWorker.new }

  before do
    allow(Project).to receive(:find).and_return(project)
  end

  describe "#perform" do
    it "sends mail" do
      subject.perform(project.id, user.email, data.stringify_keys)

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to include('Change some files')
      expect(email.to).to eq([user.email])
    end

    it "gracefully handles an input SMTP error" do
      ActionMailer::Base.deliveries.clear
      allow(Notify).to receive(:repository_push_email).and_raise(Net::SMTPFatalError)

      subject.perform(project.id, user.email, data.stringify_keys)

      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end
  end
end
