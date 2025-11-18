# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/runners/runner.html.haml', feature_category: :runner_core do
  describe 'render' do
    subject(:render_runner) do
      render 'projects/runners/runner', runner: runner, current_user: user
    end

    let_it_be(:user) { build(:user, id: 1) }
    let_it_be(:project) { build(:project, id: 1) }
    let_it_be(:runner) { build(:ci_runner, :project, id: 1, projects: [project]) }

    before do
      @project = project
    end

    shared_examples 'renders action link' do |link_text, path_proc|
      it "renders #{link_text} link" do
        render_runner
        expect(rendered).to have_link(link_text, href: instance_exec(&path_proc))
      end
    end

    shared_examples 'does not render action link' do |link_text|
      it "does not render #{link_text} link" do
        render_runner
        expect(rendered).not_to have_link(link_text)
      end
    end

    shared_examples 'renders action button' do |button_text|
      it "renders #{button_text} button" do
        render_runner
        expect(rendered).to have_button(button_text)
      end
    end

    shared_examples 'does not render action button' do |button_text|
      it "does not render #{button_text} button" do
        render_runner
        expect(rendered).not_to have_button(button_text)
      end
    end

    context 'when the runner is already enabled for the project' do
      before do
        @project_runners = [runner]
      end

      context 'when the user has update_runner access' do
        before do
          allow(view).to receive(:can?).with(user, :update_runner, runner).and_return(true)
        end

        include_examples 'renders action link', _('Edit'), -> { edit_project_runner_path(project, runner) }
      end

      context 'when the user does not have update_runner access' do
        include_examples 'does not render action link', _('Edit')
      end

      context 'when the runner belongs to only one project' do
        context 'when the user has delete_runner access' do
          before do
            allow(view).to receive(:can?).with(user, :delete_runner, runner).and_return(true)
          end

          include_examples 'renders action link', s_('Runners|Delete runner'), -> {
            project_runner_path(project, runner)
          }
        end

        context 'when the user does not have delete_runner access' do
          include_examples 'does not render action link', s_('Runners|Delete runner')
        end
      end

      context 'when the runner belongs to more than one project' do
        let(:runner_project) { build(:ci_runner_project, id: 1, project: project, runner: runner) }

        before do
          allow(runner).to receive(:belongs_to_one_project?).and_return(false)
          allow(project).to receive_message_chain(:runner_projects, :find_by_runner_id)
                              .with(runner)
                              .and_return(runner_project)
        end

        context 'when the user has admin_runners access in the project' do
          before do
            allow(view).to receive(:can?).with(user, :admin_runners, project).and_return(true)
          end

          include_examples 'renders action link', _('Disable for this project'), -> {
            project_runner_project_path(project, runner_project)
          }
        end

        context 'when the user does not have admin_runners access in the project' do
          include_examples 'does not render action link', _('Disable for this project')
        end
      end
    end

    context 'when the runner is not enabled for the project' do
      before do
        @project_runners = []
      end

      context 'when the user has admin_runners access in the project' do
        before do
          allow(view).to receive(:can?).with(user, :admin_runners, project).and_return(true)
        end

        include_examples 'renders action button', _('Enable for this project')
      end

      context 'when the user does not have admin_runners access in the project' do
        include_examples 'does not render action button', _('Enable for this project')
      end
    end
  end
end
