require 'spec_helper'

describe Environment, models: true do
  let(:environment) { create(:environment) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:deployments) }

  it { is_expected.to delegate_method(:last_deployment).to(:deployments).as(:last) }

  it { is_expected.to delegate_method(:stop_action).to(:last_deployment) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
  it { is_expected.to validate_length_of(:name).is_within(0..255) }

  it { is_expected.to validate_length_of(:external_url).is_within(0..255) }

  # To circumvent a not null violation of the name column:
  # https://github.com/thoughtbot/shoulda-matchers/issues/336
  it 'validates uniqueness of :external_url' do
    create(:environment)

    is_expected.to validate_uniqueness_of(:external_url).scoped_to(:project_id)
  end

  describe '#nullify_external_url' do
    it 'replaces a blank url with nil' do
      env = build(:environment, external_url: "")

      expect(env.save).to be true
      expect(env.external_url).to be_nil
    end
  end

  describe '#includes_commit?' do
    context 'without a last deployment' do
      it "returns false" do
        expect(environment.includes_commit?('HEAD')).to be false
      end
    end

    context 'with a last deployment' do
      let(:project)     { create(:project) }
      let(:environment) { create(:environment, project: project) }

      let!(:deployment) do
        create(:deployment, environment: environment, sha: project.commit('master').id)
      end

      context 'in the same branch' do
        it 'returns true' do
          expect(environment.includes_commit?(RepoHelpers.sample_commit)).to be true
        end
      end

      context 'not in the same branch' do
        before do
          deployment.update(sha: project.commit('feature').id)
        end

        it 'returns false' do
          expect(environment.includes_commit?(RepoHelpers.sample_commit)).to be false
        end
      end
    end
  end

  describe '#first_deployment_for' do
    let(:project)       { create(:project) }
    let!(:environment)  { create(:environment, project: project) }
    let!(:deployment)   { create(:deployment, environment: environment, ref: commit.parent.id) }
    let!(:deployment1)  { create(:deployment, environment: environment, ref: commit.id) }
    let(:head_commit)   { project.commit }
    let(:commit)        { project.commit.parent }

    it 'returns deployment id for the environment' do
      expect(environment.first_deployment_for(commit)).to eq deployment1
    end

    it 'return nil when no deployment is found' do
      expect(environment.first_deployment_for(head_commit)).to eq nil
    end
  end

  describe '#environment_type' do
    subject { environment.environment_type }

    it 'sets a environment type if name has multiple segments' do
      environment.update!(name: 'production/worker.gitlab.com')

      is_expected.to eq('production')
    end

    it 'nullifies a type if it\'s a simple name' do
      environment.update!(name: 'production')

      is_expected.to be_nil
    end
  end

  describe '#can_run_stop_action?' do
    subject { environment.can_run_stop_action? }

    context 'when no other actions' do
      it { is_expected.to be_falsey }
    end

    context 'when matching action is defined' do
      let(:build) { create(:ci_build) }
      let!(:deployment) { create(:deployment, environment: environment, deployable: build, on_stop: 'close_app') }
      let!(:close_action) { create(:ci_build, pipeline: build.pipeline, name: 'close_app', when: :manual) }

      context 'when environment is available' do
        before do
          environment.start
        end

        it { is_expected.to be_truthy }
      end

      context 'when environment is stopped' do
        before do
          environment.stop
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#run_stop!' do
    let(:user) { create(:user) }

    subject { environment.run_stop!(user) }

    before do
      expect(environment).to receive(:available?).and_call_original
    end

    context 'when no other actions' do
      context 'environment is available' do
        before do
          environment.update(state: :available)
        end

        it do
          subject

          expect(environment).to be_stopped
        end
      end

      context 'environment is already stopped' do
        before do
          environment.update(state: :stopped)
        end

        it do
          subject

          expect(environment).to be_stopped
        end
      end
    end

    context 'when matching action is defined' do
      let(:build) { create(:ci_build) }
      let!(:deployment) { create(:deployment, environment: environment, deployable: build, on_stop: 'close_app') }

      context 'when action did not yet finish' do
        let!(:close_action) { create(:ci_build, :manual, pipeline: build.pipeline, name: 'close_app') }

        it 'returns the same action' do
          expect(subject).to eq(close_action)
          expect(subject.user).to eq(user)
        end
      end

      context 'if action did finish' do
        let!(:close_action) { create(:ci_build, :manual, :success, pipeline: build.pipeline, name: 'close_app') }

        it 'returns a new action of the same type' do
          is_expected.to be_persisted
          expect(subject.name).to eq(close_action.name)
          expect(subject.user).to eq(user)
        end
      end
    end
  end
end
