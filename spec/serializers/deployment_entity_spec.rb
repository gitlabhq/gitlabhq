require 'spec_helper'

describe DeploymentEntityDetailed do
  let(:user) { create(:user) }
  let(:request) { double('request') }

  before do
    allow(request).to receive(:user).and_return(user)
  end

  let(:entity) do
    described_class.new(deployment, request: request)
  end

  let(:deployment) { create(:deployment) }

  subject { entity.as_json }

  it 'exposes internal deployment id'  do
    expect(subject).to include(:iid)
  end

  it 'exposes nested information about branch' do
    expect(subject[:ref][:name]).to eq 'master'
    expect(subject[:ref][:ref_path]).not_to be_empty
  end

  it 'exposes creation date' do
    expect(subject).to include(:created_at)
  end
end
