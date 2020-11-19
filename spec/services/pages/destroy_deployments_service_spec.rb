# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DestroyDeploymentsService do
  let(:project) { create(:project) }
  let!(:old_deployments) { create_list(:pages_deployment, 2, project: project) }
  let!(:last_deployment) { create(:pages_deployment, project: project) }
  let!(:newer_deployment) { create(:pages_deployment, project: project) }
  let!(:deployment_from_another_project) { create(:pages_deployment) }

  it 'destroys all deployments of the project' do
    expect do
      described_class.new(project).execute
    end.to change { PagesDeployment.count }.by(-4)

    expect(deployment_from_another_project.reload).to be
  end

  it 'destroy only deployments older than last deployment if it is provided' do
    expect do
      described_class.new(project, last_deployment.id).execute
    end.to change { PagesDeployment.count }.by(-2)

    expect(last_deployment.reload).to be
    expect(newer_deployment.reload).to be
    expect(deployment_from_another_project.reload).to be
  end
end
