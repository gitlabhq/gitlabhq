require 'spec_helper'

describe ::Applications::CreateService do
  let(:user) { create(:user) }
  let(:params) { attributes_for(:application) }

  subject { described_class.new(user, params) }

  it 'creates an application' do
    expect { subject.execute }.to change { Doorkeeper::Application.count }.by(1)
  end

  it 'creates an audit log' do
    stub_licensed_features(extended_audit_events: true)

    expect { subject.execute }.to change { SecurityEvent.count }.by(1)
  end
end
