require 'spec_helper'

describe 'projects/settings/ci_cd/_autodevops_form' do
  let(:project) { create(:project, :repository) }

  before do
    assign :project, project
    allow(view).to receive(:auto_devops_enabled) { true }
  end

  it 'shows a warning message about Kubernetes cluster' do
    render

    expect(rendered).to have_text('You must add a Kubernetes cluster integration to this project with a domain in order for your deployment strategy to work correctly.')
  end

  context 'when the project has an available kubernetes cluster' do
    let!(:cluster) { create(:cluster, cluster_type: :project_type, projects: [project]) }

    it 'does not show a warning message about Kubernetes cluster' do
      render

      expect(rendered).not_to have_text('You must add a Kubernetes cluster')
    end

    it 'shows a warning message about base domain' do
      render

      expect(rendered).to have_text('You must add a base domain to your Kubernetes cluster in order for your deployment strategy to work.')
    end
  end
end
