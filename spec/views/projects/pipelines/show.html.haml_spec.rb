# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pipelines/show', feature_category: :pipeline_composition do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:presented_pipeline) { pipeline.present(current_user: user) }

  before do
    allow(view).to receive(:current_user) { user }
    assign(:project, project)
    assign(:pipeline, presented_pipeline)
  end

  context 'when pipeline has errors' do
    context 'with composite_identity_forbidden error' do
      before do
        allow(pipeline).to receive_messages(composite_identity_forbidden?: true,
          failure_reason: 'Composite identity is forbidden')
        create(:ci_pipeline_message, pipeline: pipeline, content: 'some errors', severity: :error)
      end

      it 'shows warning alert with correct message' do
        render

        expect(rendered).to have_content('Unable to run pipeline')
        expect(rendered).to have_content('Composite identity is forbidden')
        expect(rendered).to have_content(
          'To enable automatic pipeline execution for composite identities, visit CI/CD Settings.'
        )
      end

      context 'with merge request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        before do
          allow(pipeline).to receive_messages(merge_request: merge_request, commit: project.repository.commit)
        end

        it 'links to merge request diffs' do
          render

          expect(rendered).to have_link('Verify changes',
            href: diffs_project_merge_request_path(project, merge_request, commit_id: pipeline.commit.id))
        end
      end

      context 'without merge request' do
        before do
          allow(pipeline).to receive_messages(merge_request: nil, commit: project.repository.commit)
        end

        it 'links to project commit' do
          render

          expect(rendered).to have_link('Verify changes',
            href: project_commit_path(project, pipeline.commit))
        end
      end

      it 'does not render the pipeline editor button' do
        project.add_developer(user)

        render

        expect(rendered).not_to have_link('Go to the pipeline editor')
      end
    end

    context 'with other errors' do
      before do
        allow(pipeline).to receive(:read_attribute).with(:failure_reason).and_return('some_other_reason')
        create(:ci_pipeline_message, pipeline: pipeline, content: 'some errors', severity: :error)
      end

      it 'shows danger alert with error messages' do
        render

        expect(rendered).to have_content('Unable to run pipeline')
        expect(rendered).to have_content('some errors')
      end

      it 'does not render the pipeline tabs' do
        render

        expect(rendered).not_to have_selector('#js-pipeline-tabs')
      end

      it 'renders the pipeline editor button with correct link for users who can view' do
        project.add_developer(user)

        render

        expect(rendered).to have_link('Go to the pipeline editor',
          href: project_ci_pipeline_editor_path(project, branch_name: pipeline.source_ref))
      end

      it 'does not render the pipeline editor button for users who cannot view' do
        render

        expect(rendered).not_to have_link('Go to the pipeline editor')
      end

      context 'when the failure reason is user_not_verified' do
        before do
          allow(pipeline).to receive_messages(user_not_verified?: true)
        end

        it 'does not show the generic "Unable to run pipeline" danger alert' do
          render

          expect(rendered).not_to have_content('Unable to run pipeline')
        end
      end
    end
  end

  context 'when pipeline does not have errors' do
    it 'does not show errors' do
      render

      expect(rendered).not_to have_content('Unable to run pipeline')
    end

    it 'renders the pipeline tabs' do
      render

      expect(rendered).to have_selector('#js-pipeline-tabs')
    end
  end
end
