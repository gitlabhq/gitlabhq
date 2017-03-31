require 'spec_helper'

describe EnvironmentEntity do
  let(:entity) do
    described_class.new(environment, request: double(user: nil))
  end

  let(:environment) { create(:environment) }
  subject { entity.as_json }

  it 'exposes latest deployment' do
    expect(subject).to include(:last_deployment)
  end

  it 'exposes core elements of environment' do
    expect(subject).to include(:id, :name, :state, :environment_path)
  end

  context 'metrics disabled' do
    before do
      allow(environment).to receive(:has_metrics?).and_return(false)
    end

    it "doesn't expose metrics path" do
      expect(subject).not_to include(:metrics_path)
    end
  end

  context 'metrics enabled' do
    before do
      allow(environment).to receive(:has_metrics?).and_return(true)
    end

    it 'exposes metrics path' do
      expect(subject).to include(:metrics_path)
    end
  end

  context 'with deployment service ready' do
    before do
      allow(environment).to receive(:deployment_service_ready?).and_return(true)
    end

    it 'exposes rollout_status_path' do
      expected = '/' + [environment.project.full_path, 'environments', environment.id, 'status.json'].join('/')

      expect(subject[:rollout_status_path]).to eq(expected)
    end
  end
end
