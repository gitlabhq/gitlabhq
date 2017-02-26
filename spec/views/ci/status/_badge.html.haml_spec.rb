require 'spec_helper'

describe 'ci/status/_badge', :view do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :private) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  context 'when rendering status for build' do
    let(:build) do
      create(:ci_build, :success, pipeline: pipeline)
    end

    context 'when status has details' do
      before do
        project.add_developer(user)
      end

      it 'has link to build details page' do
        details_path =  namespace_project_build_path(
          project.namespace, project, build)

        render_status(build)

        expect(rendered).to have_link 'passed', href: details_path
      end
    end

    context 'when status does not have details' do
      before do
        render_status(build)
      end

      it 'contains build status text' do
        expect(rendered).to have_content 'passed'
      end

      it 'does not contain links' do
        expect(rendered).not_to have_link 'passed'
      end
    end
  end

  context 'when rendering status for external job' do
    before do
      project.add_developer(use)

      render_status(external_job)
    end

    context 'status has external target url' do
      let(:external_job) do
        create(:generic_commit_status, status: :running,
                                       pipeline: pipeline,
                                       target_url: 'http://gitlab.com')
      end

      it 'contains valid commit status text' do
        expect(rendered).to have_content 'running'
      end

      it 'has link to external status page' do
        expect(rendered).to have_link 'running', href: 'http://gitlab.com'
      end
    end

    context 'status do not have external target url' do
      let(:external_job) do
        create(:generic_commit_status, status: :canceled)
      end

      it 'contains valid commit status text' do
        expect(rendered).to have_content 'canceled'
      end

      it 'has link to external status page' do
        expect(rendered).not_to have_link 'canceled'
      end
    end
  end

  def render_status(resource)
    render 'ci/status/badge', status: resource.detailed_status(user)
  end
end
