require "spec_helper"

describe ::Applications::CreateService do
  let(:user) { create(:user) }
  let(:params) { attributes_for(:application) }
  let(:request) do
    if Gitlab.rails5?
      ActionController::TestRequest.new({ remote_ip: "127.0.0.1" }, ActionController::TestSession.new)
    else
      ActionController::TestRequest.new(remote_ip: "127.0.0.1")
    end
  end

  subject { described_class.new(user, params) }

  it { expect { subject.execute(request) }.to change { Doorkeeper::Application.count }.by(1) }
end
