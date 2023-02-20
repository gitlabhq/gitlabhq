# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DestroyDeploymentsService, feature_category: :pages do
  let_it_be(:project) { create(:project) }
  let!(:old_deployments) { create_list(:pages_deployment, 2, project: project) }
  let!(:last_deployment) { create(:pages_deployment, project: project) }
  let!(:newer_deployment) { create(:pages_deployment, project: project) }
  let!(:deployment_from_another_project) { create(:pages_deployment) }

  it 'destroys all deployments of the project' do
    expect { described_class.new(project).execute }
      .to change { PagesDeployment.count }.by(-4)

    expect(deployment_from_another_project.reload).to be_persisted
  end

  it 'destroy only deployments older than last deployment if it is provided' do
    expect { described_class.new(project, last_deployment.id).execute }
      .to change { PagesDeployment.count }.by(-2)

    expect(last_deployment.reload).to be_persisted
    expect(newer_deployment.reload).to be_persisted
    expect(deployment_from_another_project.reload).to be_persisted
  end
end
