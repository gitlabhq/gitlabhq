require 'spec_helper'

describe DeployKeys::CreateService do
  let(:user) { create(:user) }
  let(:params) { attributes_for(:deploy_key) }

  subject { described_class.new(user, params) }

  it "creates a deploy key" do
    expect { subject.execute }.to change { DeployKey.where(params.merge(user: user)).count }.by(1)
  end
end
