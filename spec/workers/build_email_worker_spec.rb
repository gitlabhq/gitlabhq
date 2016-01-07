require 'spec_helper'

describe BuildEmailWorker do
  include RepoHelpers

  let(:build) { create(:ci_build) }
  let(:user) { create(:user) }
  let(:data) { Gitlab::BuildDataBuilder.build(build) }

  subject { BuildEmailWorker.new }

  before do
    allow(build).to receive(:execute_hooks).and_return(false)
    build.success
  end

  describe "#perform" do
    it "sends mail" do
      subject.perform(build.id, [user.email], data.stringify_keys)

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to include('Build success for')
      expect(email.to).to eq([user.email])
    end

    it "gracefully handles an input SMTP error" do
      ActionMailer::Base.deliveries.clear
      allow(Notify).to receive(:build_success_email).and_raise(Net::SMTPFatalError)

      subject.perform(build.id, [user.email], data.stringify_keys)

      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end
  end
end
