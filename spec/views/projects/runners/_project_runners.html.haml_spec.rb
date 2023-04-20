# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/runners/_project_runners.html.haml', feature_category: :runner do
  describe 'render' do
    let_it_be(:user) { build(:user) }
    let_it_be(:project) { build(:project) }

    before do
      @project = project
      @assignable_runners = []
      @project_runners = []
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:reset_registration_token_namespace_project_settings_ci_cd_path).and_return('banana_url')
    end

    context 'when create_runner_workflow_for_namespace is disabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: false)
      end

      context 'when project runner registration is allowed' do
        before do
          stub_application_setting(valid_runner_registrars: ['project'])
          allow(view).to receive(:can?).with(user, :register_project_runners, project).and_return(true)
        end

        it 'enables the Remove project button for a project' do
          render 'projects/runners/project_runners', project: project

          expect(rendered).to have_selector '#js-install-runner'
          expect(rendered).not_to have_content 'Please contact an admin to register runners.'
        end
      end

      context 'when project runner registration is not allowed' do
        before do
          stub_application_setting(valid_runner_registrars: ['group'])
        end

        it 'does not enable the Remove project button for a project' do
          render 'projects/runners/project_runners', project: project

          expect(rendered).to have_content 'Please contact an admin to register runners.'
          expect(rendered).not_to have_selector '#js-install-runner'
        end
      end
    end

    context 'when create_runner_workflow_for_namespace is enabled' do
      before do
        stub_feature_flags(create_runner_workflow_for_namespace: project.namespace)
      end

      context 'when user can create project runner' do
        before do
          allow(view).to receive(:can?).with(user, :create_runner, project).and_return(true)
        end

        it 'renders the New project runner button' do
          render 'projects/runners/project_runners', project: project

          expect(rendered).to have_link(s_('Runners|New project runner'), href: new_project_runner_path(project))
        end
      end

      context 'when user cannot create project runner' do
        before do
          allow(view).to receive(:can?).with(user, :create_runner, project).and_return(false)
        end

        it 'does not render the New project runner button' do
          render 'projects/runners/project_runners', project: project

          expect(rendered).not_to have_link(s_('Runners|New project runner'))
        end
      end
    end
  end
end
