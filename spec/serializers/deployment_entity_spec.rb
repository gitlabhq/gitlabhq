require 'spec_helper'

describe DeploymentEntity do
  let(:user) { create(:user) }
  let(:request) { double('request') }
  let(:deployment) { create(:deployment) }
  let(:entity) { described_class.new(deployment, request: request) }
  subject { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  it 'exposes internal deployment id'  do
    expect(subject).to include(:iid)
  end

  it 'exposes nested information about branch' do
    expect(subject[:ref][:name]).to eq 'master'
  end

  it 'exposes creation date' do
    expect(subject).to include(:created_at)
  end
end
