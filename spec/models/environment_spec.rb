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

  describe '#deployment_for' do
    let(:project)       { create(:project) }
    let!(:environment)  { create(:environment, project: project) }
    let(:deployment)    { create(:deployment, environment: environment) }
    let(:deployment1)   { create(:deployment, environment: environment, sha: commit.id) }
    let(:commit)        { project.commit }

    before do
      deployment.create_refs
      deployment1.create_refs
    end

    it 'selects deployed environments' do
      expect(environment.deployment_for(commit)).to eq deployment.id.to_s
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
end
