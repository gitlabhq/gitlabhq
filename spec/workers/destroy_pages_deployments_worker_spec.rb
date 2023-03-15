# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DestroyPagesDeploymentsWorker, feature_category: :pages do
  subject(:worker) { described_class.new }

  let(:project) { create(:project) }
  let!(:old_deployment) { create(:pages_deployment, project: project) }
  let!(:last_deployment) { create(:pages_deployment, project: project) }
  let!(:another_deployment) { create(:pages_deployment) }

  it "doesn't fail if project is already removed" do
    expect do
      worker.perform(-1)
    end.not_to raise_error
  end

  it 'can be called without last_deployment_id' do
    expect_next_instance_of(::Pages::DestroyDeploymentsService, project, nil) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    expect do
      worker.perform(project.id)
    end.to change { PagesDeployment.count }.by(-2)
  end

  it 'calls destroy service' do
    expect_next_instance_of(::Pages::DestroyDeploymentsService, project, last_deployment.id) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    expect do
      worker.perform(project.id, last_deployment.id)
    end.to change { PagesDeployment.count }.by(-1)
  end
end
