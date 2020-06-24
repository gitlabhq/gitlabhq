# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/deployments/_confirm_rollback_modal' do
  let(:environment) { create(:environment, :with_review_app) }
  let(:deployments) { environment.deployments }
  let(:project) { environment.project }

  before do
    assign(:environment, environment)
    assign(:deployments, deployments)
    assign(:project, project)
  end

  context 'when re-deploying last deployment' do
    let(:deployment) { deployments.first }

    before do
      allow(view).to receive(:deployment).and_return(deployment)
    end

    it 'shows "re-deploy"' do
      render

      expect(rendered).to have_selector('h4', text: "Re-deploy environment #{environment.name}?")
      expect(rendered).to have_selector('p', text: "This action will relaunch the job for commit #{deployment.short_sha}, putting the environment in a previous version. Are you sure you want to continue?")
      expect(rendered).to have_selector('a.btn-danger', text: 'Re-deploy')
    end

    it 'links to re-deploying the environment' do
      expected_link = retry_project_job_path(environment.project, deployment.deployable)

      render

      expect(rendered).to have_selector("a[href='#{expected_link}']", text: 'Re-deploy')
    end
  end

  context 'when rolling back to previous deployment' do
    let(:deployment) { create(:deployment, environment: environment) }

    before do
      allow(view).to receive(:deployment).and_return(deployment)
    end

    it 'shows "rollback"' do
      render

      expect(rendered).to have_selector('h4', text: "Rollback environment #{environment.name}?")
      expect(rendered).to have_selector('p', text: "This action will run the job defined by #{environment.name} for commit #{deployment.short_sha}, putting the environment in a previous version. You can revert it by re-deploying the latest version of your application. Are you sure you want to continue?")
      expect(rendered).to have_selector('a.btn-danger', text: 'Rollback')
    end

    it 'links to re-deploying the environment' do
      expected_link = retry_project_job_path(environment.project, deployment.deployable)

      render

      expect(rendered).to have_selector("a[href='#{expected_link}']", text: 'Rollback')
    end
  end
end
