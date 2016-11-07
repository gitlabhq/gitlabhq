require 'spec_helper'

describe DeploymentEntity do
  let(:entity) do
    described_class.new(deployment, request: double)
  end

  let(:deployment) { create(:deployment) }

  subject { entity.as_json }

  it 'exposes internal deployment id'  do
    expect(subject).to include(:iid)
  end

  it 'exposes nested information about branch' do
    expect(subject[:ref][:name]).to eq 'master'
    expect(subject[:ref][:ref_url]).not_to be_empty
  end
end
