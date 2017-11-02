require 'spec_helper'

describe ::Applications::CreateService do
  let(:user) { create(:user) }
  let(:params) { attributes_for(:application) }
  let(:request) { ActionController::TestRequest.new(remote_ip: '127.0.0.1') }

  subject { described_class.new(user, params) }

  it 'creates an application' do
    expect { subject.execute(request) }.to change { Doorkeeper::Application.count }.by(1)
  end
end
