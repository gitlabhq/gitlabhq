require 'spec_helper'

describe Environment, models: true do
  let(:environment) { create(:environment) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:deployments) }

  it { is_expected.to delegate_method(:last_deployment).to(:deployments).as(:last) }

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
end
