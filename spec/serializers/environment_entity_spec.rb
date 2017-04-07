require 'spec_helper'

describe EnvironmentEntity do
  let(:user) { create(:user) }
  let(:environment) { create(:environment) }

  let(:entity) do
    described_class.new(environment, request: double(user: user))
  end

  subject { entity.as_json }

  before do
    allow_any_instance_of(License).to receive(:add_on?).and_return(false)

    environment.project.team << [user, :master]
  end

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
      allow_any_instance_of(License).to receive(:add_on?).with('GitLab_DeployBoard').and_return(true)
      allow(environment).to receive(:deployment_service_ready?).and_return(true)
    end

    it 'exposes rollout_status_path' do
      expected = '/' + [environment.project.full_path, 'environments', environment.id, 'status.json'].join('/')

      expect(subject[:rollout_status_path]).to eq(expected)
    end
  end

  context 'when license does not has the GitLab_DeployBoard add-on' do
    before do
      allow_any_instance_of(License).to receive(:add_on?).with('GitLab_DeployBoard').and_return(false)
      allow(environment).to receive(:deployment_service_ready?).and_return(true)
    end

    it 'does not expose rollout_status_path' do
      expect(subject[:rollout_status_path]).to be_blank
    end
  end
end
