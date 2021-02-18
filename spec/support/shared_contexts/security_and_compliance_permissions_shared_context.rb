# frozen_string_literal: true

RSpec.shared_context '"Security & Compliance" permissions' do
  let(:project_instance) { an_instance_of(Project) }
  let(:user_instance) { an_instance_of(User) }
  let(:before_request_defined) { false }
  let(:valid_request) {}

  def self.before_request(&block)
    return unless block

    let(:before_request_call) { instance_exec(&block) }
    let(:before_request_defined) { true }
  end

  before do
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user_instance, :access_security_and_compliance, project_instance).and_return(true)
  end

  context 'when the "Security & Compliance" feature is disabled' do
    subject { response }

    before do
      before_request_call if before_request_defined

      allow(Ability).to receive(:allowed?).with(user_instance, :access_security_and_compliance, project_instance).and_return(false)
      valid_request
    end

    it { is_expected.to have_gitlab_http_status(:not_found) }
  end
end
