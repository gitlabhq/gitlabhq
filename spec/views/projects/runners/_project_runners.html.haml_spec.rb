# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/runners/_project_runners.html.haml', feature_category: :runner_core do
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

    context 'when user can create project runner' do
      before do
        allow(view).to receive(:can?).with(user, :create_runners, project).and_return(true)
      end

      it 'renders the New project runner button' do
        render 'projects/runners/project_runners', project: project

        expect(rendered).to have_link(s_('Runners|Create project runner'), href: new_project_runner_path(project))
      end
    end

    context 'when user cannot create project runner' do
      before do
        allow(view).to receive(:can?).with(user, :create_runners, project).and_return(false)
      end

      it 'does not render the New project runner button' do
        render 'projects/runners/project_runners', project: project

        expect(rendered).not_to have_link(s_('Runners|Create project runner'))
      end
    end

    context 'when user can read project runners' do
      before do
        allow(view).to receive(:can?).with(user, :read_runners, project).and_return(true)
      end

      context 'when there are project runners assigned to the project' do
        let(:runner) { build(:ci_runner, :project, id: 1001, projects: [project]) }

        before do
          @project_runners = Kaminari.paginate_array([runner]).page(1).per(20)
        end

        it 'renders the list of assigned runners' do
          render 'projects/runners/project_runners', project: project

          expect(rendered).to have_link(href: project_runner_path(project, runner),
            text: "##{runner.id} (#{runner.short_sha})")
          expect(rendered).to have_text(s_('Runners|Assigned project runners'))
        end
      end

      context 'when there are no project runners assigned to the project' do
        before do
          @project_runners = Kaminari.paginate_array([]).page(1).per(20)
        end

        it 'does not render the list of assigned projects' do
          render 'projects/runners/project_runners', project: project

          expect(rendered).not_to have_text(s_('Runners|Assigned project runners'))
        end
      end

      context 'when there are other available runners to assign' do
        let(:other_project) { build(:project, id: 100) }
        let(:runner) { build(:ci_runner, :project, id: 101, projects: [other_project]) }

        before do
          @project_runners = Kaminari.paginate_array([]).page(1).per(20)
          @assignable_runners = Kaminari.paginate_array([runner]).page(1).per(20)
          allow(view).to receive(:can?).with(user, :admin_runners, project).and_return(true)
        end

        it 'renders the list of available runners' do
          render 'projects/runners/project_runners', project: project

          expect(rendered).to have_text(_('Other available runners'))
          expect(rendered).to have_text(_('Enable for this project'))
        end
      end

      context 'when there are no other available runners to assign' do
        before do
          @project_runners = Kaminari.paginate_array([]).page(1).per(20)
          @assignable_runners = Kaminari.paginate_array([]).page(1).per(20)
        end

        it 'does not render the list of available runners' do
          render 'projects/runners/project_runners', project: project

          expect(rendered).not_to have_text(_('Other available runners'))
        end
      end
    end

    context 'when user cannot read project runners' do
      before do
        allow(view).to receive(:can?).with(user, :read_runners, project).and_return(false)
      end

      it 'neither render the list of assigned projects nor the list of available runners' do
        render 'projects/runners/project_runners', project: project

        expect(rendered).not_to have_text(s_('Runners|Assigned project runners'))
        expect(rendered).not_to have_text(_('Other available runners'))
      end
    end
  end
end
