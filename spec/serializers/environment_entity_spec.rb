require 'spec_helper'

describe EnvironmentEntity do
  let(:entity) do
    described_class.new(environment, request: double)
  end

  let(:environment) { create(:environment) }
  subject { entity.as_json }

  it 'exposes latest deployment' do
    expect(subject).to include(:last_deployment)
  end

  it 'exposes core elements of environment' do
    expect(subject).to include(:id, :name, :state, :environment_path)
  end
end
