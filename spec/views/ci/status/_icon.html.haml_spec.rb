# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'ci/status/_icon' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :private) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  context 'when rendering status for build' do
    let(:build) do
      create(:ci_build, :success, pipeline: pipeline)
    end

    context 'when user has ability to see details' do
      before do
        project.add_developer(user)
      end

      it 'has link to build details page' do
        details_path = project_job_path(project, build)

        render_status(build)

        expect(rendered).to have_link(href: details_path)
      end
    end

    context 'when user do not have ability to see build details' do
      before do
        render_status(build)
      end

      it 'contains build status text' do
        expect(rendered).to have_css('[data-testid="status_success_borderless-icon"]')
      end

      it 'does not contain links' do
        expect(rendered).not_to have_link
      end
    end
  end

  context 'when rendering status for external job' do
    context 'when user has ability to see commit status details' do
      before do
        project.add_developer(user)
      end

      context 'status has external target url' do
        before do
          external_job = create(
            :generic_commit_status,
            status: :running,
            pipeline: pipeline,
            target_url: 'http://gitlab.com'
          )

          render_status(external_job)
        end

        it 'contains valid commit status text' do
          expect(rendered).to have_css('[data-testid="status_running_borderless-icon"]')
        end

        it 'has link to external status page' do
          expect(rendered).to have_link(href: 'http://gitlab.com')
        end
      end

      context 'status do not have external target url' do
        before do
          external_job = create(:generic_commit_status, status: :canceled)

          render_status(external_job)
        end

        it 'contains valid commit status text' do
          expect(rendered).to have_css('[data-testid="status_canceled_borderless-icon"]')
        end

        it 'has link to external status page' do
          expect(rendered).not_to have_link
        end
      end
    end
  end

  def render_status(resource)
    render 'ci/status/icon', status: resource.detailed_status(user)
  end
end
