require 'spec_helper'

describe Environment, models: true do
  let(:project) { create(:empty_project) }
  subject(:environment) { create(:environment, project: project) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:deployments) }

  it { is_expected.to delegate_method(:last_deployment).to(:deployments).as(:last) }

  it { is_expected.to delegate_method(:stop_action).to(:last_deployment) }
  it { is_expected.to delegate_method(:manual_actions).to(:last_deployment) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }

  it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:project_id) }
  it { is_expected.to validate_length_of(:slug).is_at_most(24) }

  it { is_expected.to validate_length_of(:external_url).is_at_most(255) }
  it { is_expected.to validate_uniqueness_of(:external_url).scoped_to(:project_id) }

  describe '#nullify_external_url' do
    it 'replaces a blank url with nil' do
      env = build(:environment, external_url: "")

      expect(env.save).to be true
      expect(env.external_url).to be_nil
    end
  end

  describe '#includes_commit?' do
    let(:project) { create(:project) }

    context 'without a last deployment' do
      it "returns false" do
        expect(environment.includes_commit?('HEAD')).to be false
      end
    end

    context 'with a last deployment' do
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

  describe '#stoppable?' do
    subject { environment.stoppable? }

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

  describe '#stop!' do
    let(:user) { create(:user) }

    subject { environment.stop!(user) }

    before do
      expect(environment).to receive(:stoppable?).and_call_original
    end

    context 'when no other actions' do
      it { is_expected.to be_nil }
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

  describe 'recently_updated_on_branch?' do
    subject { environment.recently_updated_on_branch?('feature') }

    context 'when last deployment to environment is the most recent one' do
      before do
        create(:deployment, environment: environment, ref: 'feature')
      end

      it { is_expected.to be true }
    end

    context 'when last deployment to environment is not the most recent' do
      before do
        create(:deployment, environment: environment, ref: 'feature')
        create(:deployment, environment: environment, ref: 'master')
      end

      it { is_expected.to be false }
    end
  end

  describe '#actions_for' do
    let(:deployment) { create(:deployment, environment: environment) }
    let(:pipeline) { deployment.deployable.pipeline }
    let!(:review_action) { create(:ci_build, :manual, name: 'review-apps', pipeline: pipeline, environment: 'review/$CI_BUILD_REF_NAME' )}
    let!(:production_action) { create(:ci_build, :manual, name: 'production', pipeline: pipeline, environment: 'production' )}

    it 'returns a list of actions with matching environment' do
      expect(environment.actions_for('review/master')).to contain_exactly(review_action)
    end
  end

  describe '#has_terminals?' do
    subject { environment.has_terminals? }

    context 'when the enviroment is available' do
      context 'with a deployment service' do
        let(:project) { create(:kubernetes_project) }

        context 'and a deployment' do
          let!(:deployment) { create(:deployment, environment: environment) }
          it { is_expected.to be_truthy }
        end

        context 'but no deployments' do
          it { is_expected.to be_falsy }
        end
      end

      context 'without a deployment service' do
        it { is_expected.to be_falsy }
      end
    end

    context 'when the environment is unavailable' do
      let(:project) { create(:kubernetes_project) }
      before { environment.stop }
      it { is_expected.to be_falsy }
    end
  end

  describe '#terminals' do
    let(:project) { create(:kubernetes_project) }
    subject { environment.terminals }

    context 'when the environment has terminals' do
      before { allow(environment).to receive(:has_terminals?).and_return(true) }

      it 'returns the terminals from the deployment service' do
        expect(project.deployment_service).
          to receive(:terminals).with(environment).
          and_return(:fake_terminals)

        is_expected.to eq(:fake_terminals)
      end
    end

    context 'when the environment does not have terminals' do
      before { allow(environment).to receive(:has_terminals?).and_return(false) }
      it { is_expected.to eq(nil) }
    end
  end

  describe '#slug' do
    it "is automatically generated" do
      expect(environment.slug).not_to be_nil
    end

    it "is not regenerated if name changes" do
      original_slug = environment.slug
      environment.update_attributes!(name: environment.name.reverse)

      expect(environment.slug).to eq(original_slug)
    end
  end

  describe '#generate_slug' do
    SUFFIX = "-[a-z0-9]{6}"
    {
      "staging-12345678901234567" => "staging-123456789" + SUFFIX,
      "9-staging-123456789012345" => "env-9-staging-123" + SUFFIX,
      "staging-1234567890123456"  => "staging-1234567890123456",
      "production"                => "production",
      "PRODUCTION"                => "production" + SUFFIX,
      "review/1-foo"              => "review-1-foo" + SUFFIX,
      "1-foo"                     => "env-1-foo" + SUFFIX,
      "1/foo"                     => "env-1-foo" + SUFFIX,
      "foo-"                      => "foo" + SUFFIX,
    }.each do |name, matcher|
      it "returns a slug matching #{matcher}, given #{name}" do
        slug = described_class.new(name: name).generate_slug

        expect(slug).to match(/\A#{matcher}\z/)
      end
    end
  end
end
