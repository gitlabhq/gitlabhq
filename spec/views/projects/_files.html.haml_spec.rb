# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_files' do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:source_project) { create(:project, :repository, :public) }

  context 'when the project is a fork' do
    let_it_be(:project) { fork_project(source_project, user, { repository: true }) }

    before do
      assign(:project, project)
      assign(:ref, project.default_branch)
      assign(:path, '/')
      assign(:id, project.commit.id)

      allow(view).to receive(:current_user).and_return(user)
    end

    context 'when user can read fork source' do
      before do
        allow(view).to receive(:can?).with(user, :read_project, source_project).and_return(true)
      end

      it 'shows the forked-from project' do
        render

        expect(rendered).to have_content("Forked from #{source_project.full_name}")
        expect(rendered).to have_content("Up to date with upstream repository")
      end

      context 'when fork_divergence_counts is disabled' do
        before do
          stub_feature_flags(fork_divergence_counts: false)
        end

        it 'does not show fork info' do
          render

          expect(rendered).not_to have_content("Forked from #{source_project.full_name}")
          expect(rendered).not_to have_content("Up to date with upstream repository")
        end
      end
    end

    context 'when user cannot read fork source' do
      before do
        allow(view).to receive(:can?).with(user, :read_project, source_project).and_return(false)
      end

      it 'does not show the forked-from project' do
        render

        expect(rendered).to have_content("Forked from an inaccessible project")
      end

      context 'when fork_divergence_counts is disabled' do
        before do
          stub_feature_flags(fork_divergence_counts: false)
        end

        it 'does not show fork info' do
          render

          expect(rendered).not_to have_content("Forked from an inaccessible project")
        end
      end
    end
  end
end
