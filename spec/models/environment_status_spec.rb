require 'spec_helper'

describe EnvironmentStatus do
  let(:deployment)    { create(:deployment, :review_app) }
  let(:environment)   { deployment.environment}
  let(:project)       { deployment.project }
  let(:merge_request) { create(:merge_request, :deployed_review_app, deployment: deployment) }

  subject(:environment_status) { described_class.new(environment, merge_request) }

  it { is_expected.to delegate_method(:id).to(:environment) }
  it { is_expected.to delegate_method(:name).to(:environment) }
  it { is_expected.to delegate_method(:project).to(:environment) }

  describe '#project' do
    subject { environment_status.project }

    it { is_expected.to eq(project) }
  end

  describe '#merge_request' do
    subject { environment_status.merge_request }

    it { is_expected.to eq(merge_request) }
  end

  describe '#deployment' do
    subject { environment_status.deployment }

    it { is_expected.to eq(deployment) }
  end

  describe '#deployed_at' do
    it 'delegates to deployment.created_at' do
      expect(environment_status.deployment).to receive(:try).with(:created_at).and_call_original

      environment_status.deployed_at
    end
  end
end
