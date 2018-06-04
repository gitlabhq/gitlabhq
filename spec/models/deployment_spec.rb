require 'spec_helper'

describe Deployment do
  subject { build(:deployment) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:environment) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:deployable) }

  it { is_expected.to delegate_method(:name).to(:environment).with_prefix }
  it { is_expected.to delegate_method(:commit).to(:project) }
  it { is_expected.to delegate_method(:commit_title).to(:commit).as(:try) }
  it { is_expected.to delegate_method(:manual_actions).to(:deployable).as(:try) }

  it { is_expected.to validate_presence_of(:ref) }
  it { is_expected.to validate_presence_of(:sha) }

  describe 'modules' do
    it_behaves_like 'AtomicInternalId' do
      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:deployment) }
      let(:scope_attrs) { { project: instance.project } }
      let(:usage) { :deployments }
    end
  end

  describe 'after_create callbacks' do
    let(:environment) { create(:environment) }
    let(:store) { Gitlab::EtagCaching::Store.new }

    it 'invalidates the environment etag cache' do
      old_value = store.get(environment.etag_cache_key)

      create(:deployment, environment: environment)

      expect(store.get(environment.etag_cache_key)).not_to eq(old_value)
    end
  end

  describe '#includes_commit?' do
    let(:project) { create(:project, :repository) }
    let(:environment) { create(:environment, project: project) }
    let(:deployment) do
      create(:deployment, environment: environment, sha: project.commit.id)
    end

    context 'when there is no project commit' do
      it 'returns false' do
        commit = project.commit('feature')

        expect(deployment.includes_commit?(commit)).to be false
      end
    end

    context 'when they share the same tree branch' do
      it 'returns true' do
        commit = project.commit

        expect(deployment.includes_commit?(commit)).to be true
      end
    end

    context 'when the SHA for the deployment does not exist in the repo' do
      it 'returns false' do
        deployment.update(sha: Gitlab::Git::BLANK_SHA)
        commit = project.commit

        expect(deployment.includes_commit?(commit)).to be false
      end
    end
  end

  describe '#metrics' do
    let(:deployment) { create(:deployment) }
    let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true) }

    subject { deployment.metrics }

    context 'metrics are disabled' do
      it { is_expected.to eq({}) }
    end

    context 'metrics are enabled' do
      let(:simple_metrics) do
        {
          success: true,
          metrics: {},
          last_update: 42
        }
      end

      before do
        allow(deployment).to receive(:prometheus_adapter).and_return(prometheus_adapter)
        allow(prometheus_adapter).to receive(:query).with(:deployment, deployment).and_return(simple_metrics)
      end

      it { is_expected.to eq(simple_metrics.merge({ deployment_time: deployment.created_at.to_i })) }
    end
  end

  describe '#additional_metrics' do
    let(:project) { create(:project, :repository) }
    let(:deployment) { create(:deployment, project: project) }

    subject { deployment.additional_metrics }

    context 'metrics are disabled' do
      it { is_expected.to eq({}) }
    end

    context 'metrics are enabled' do
      let(:simple_metrics) do
        {
          success: true,
          metrics: {},
          last_update: 42
        }
      end

      let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true) }

      before do
        allow(deployment).to receive(:prometheus_adapter).and_return(prometheus_adapter)
        allow(prometheus_adapter).to receive(:query).with(:additional_metrics_deployment, deployment).and_return(simple_metrics)
      end

      it { is_expected.to eq(simple_metrics.merge({ deployment_time: deployment.created_at.to_i })) }
    end
  end

  describe '#stop_action' do
    let(:build) { create(:ci_build) }

    subject { deployment.stop_action }

    context 'when no other actions' do
      let(:deployment) { FactoryBot.build(:deployment, deployable: build) }

      it { is_expected.to be_nil }
    end

    context 'with other actions' do
      let!(:close_action) { create(:ci_build, :manual, pipeline: build.pipeline, name: 'close_app') }

      context 'when matching action is defined' do
        let(:deployment) { FactoryBot.build(:deployment, deployable: build, on_stop: 'close_other_app') }

        it { is_expected.to be_nil }
      end

      context 'when no matching action is defined' do
        let(:deployment) { FactoryBot.build(:deployment, deployable: build, on_stop: 'close_app') }

        it { is_expected.to eq(close_action) }
      end
    end
  end

  describe '#stop_action?' do
    subject { deployment.stop_action? }

    context 'when no other actions' do
      let(:deployment) { build(:deployment) }

      it { is_expected.to be_falsey }
    end

    context 'when matching action is defined' do
      let(:build) { create(:ci_build) }
      let(:deployment) { FactoryBot.build(:deployment, deployable: build, on_stop: 'close_app') }
      let!(:close_action) { create(:ci_build, :manual, pipeline: build.pipeline, name: 'close_app') }

      it { is_expected.to be_truthy }
    end
  end
end
