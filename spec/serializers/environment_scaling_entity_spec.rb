require 'spec_helper'

describe EnvironmentScalingEntity do
  let(:environment_scaling) { create(:environment_scaling) }
  let(:entity) { described_class.new(environment_scaling, request: double) }

  subject { entity.as_json }

  it 'exposes replicas' do
    expect(subject).to include(:replicas)
  end
end
