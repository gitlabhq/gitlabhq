# frozen_string_literal: true

RSpec.shared_examples 'a deployment job waiting for approval' do |factory_type|
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:job) { create(factory_type, :manual, environment: 'production', project: project) }

  subject { described_class.new(Gitlab::Ci::Status::Core.new(job, user)) }

  describe '.matches?' do
    subject { described_class.matches?(job, user) }

    let(:job) { create(factory_type, :manual, environment: 'production', project: project) }
    let!(:deployment) { create(:deployment, deployment_status, deployable: job, project: project) }

    context 'when job is waiting for approval' do
      let(:deployment_status) { :blocked }

      before do
        allow(deployment).to receive(:waiting_for_approval?).and_return(true)
      end

      it 'is a correct match' do
        expect(subject).to be_truthy
      end
    end

    context 'when job is not waiting for approval' do
      let(:deployment_status) { :created }

      it 'does not match' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#illustration' do
    before do
      environment = create(:environment, name: 'production', project: project)
      create(:deployment, :blocked, project: project, environment: environment, deployable: job)
    end

    it { expect(subject.illustration).to include(:image, :size) }
    it { expect(subject.illustration[:title]).to eq('Waiting for approvals') }

    it 'has the correct message' do
      expected_message = "This job deploys to the protected environment \"production\", which requires approvals. " \
        "You can approve or reject the deployment on the deployment details page."
      expect(subject.illustration[:content]).to eq expected_message
    end
  end

  describe '#has_action?' do
    it { expect(subject.has_action?).to be_truthy }
  end

  describe '#action_icon' do
    it { expect(subject.action_icon).to be_nil }
  end

  describe '#action_title' do
    it { expect(subject.action_title).to be_nil }
  end

  describe '#action_button_title' do
    it { expect(subject.action_button_title).to eq('View deployment details page') }
  end

  describe '#action_path' do
    let!(:environment) { create(:environment, name: 'production', project: project) }
    let!(:deployment) { create(:deployment, :blocked, project: project, environment: environment, deployable: job) }

    it 'points to the deployment details page' do
      expected_path = Rails.application.routes.url_helpers.project_environment_deployment_path(
        project, environment, deployment)
      expect(subject.action_path).to eq expected_path
    end
  end

  describe '#action_method' do
    it { expect(subject.action_method).to eq(:get) }
  end
end
