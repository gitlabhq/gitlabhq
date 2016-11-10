require 'spec_helper'

describe Deployment, models: true do
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

  describe '#includes_commit?' do
    let(:project)     { create(:project) }
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

  describe '#stop_action' do
    let(:build) { create(:ci_build) }

    subject { deployment.stop_action }

    context 'when no other actions' do
      let(:deployment) { FactoryGirl.build(:deployment, deployable: build) }

      it { is_expected.to be_nil }
    end

    context 'with other actions' do
      let!(:close_action) { create(:ci_build, pipeline: build.pipeline, name: 'close_app', when: :manual) }

      context 'when matching action is defined' do
        let(:deployment) { FactoryGirl.build(:deployment, deployable: build, on_stop: 'close_other_app') }

        it { is_expected.to be_nil }
      end

      context 'when no matching action is defined' do
        let(:deployment) { FactoryGirl.build(:deployment, deployable: build, on_stop: 'close_app') }

        it { is_expected.to eq(close_action) }
      end
    end
  end

  describe '#stoppable?' do
    subject { deployment.stoppable? }

    context 'when no other actions' do
      let(:deployment) { build(:deployment) }

      it { is_expected.to be_falsey }
    end

    context 'when matching action is defined' do
      let(:build) { create(:ci_build) }
      let(:deployment) { FactoryGirl.build(:deployment, deployable: build, on_stop: 'close_app') }
      let!(:close_action) { create(:ci_build, pipeline: build.pipeline, name: 'close_app', when: :manual) }

      it { is_expected.to be_truthy }
    end
  end
end
