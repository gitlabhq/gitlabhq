# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/commits/_commit.html.haml', feature_category: :source_code_management do
  let(:template) { 'projects/commits/commit' }
  let(:project) { create(:project, :repository) }
  let(:commit) { project.repository.commit(ref) }

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
  end

  context 'with a signed commit' do
    let(:ref) { GpgHelpers::SIGNED_COMMIT_SHA }

    it 'does not display a loading spinner for GPG status' do
      render partial: template, formats: :html, locals: {
        project: project,
        ref: ref,
        commit: commit
      }

      within '.signature-badge' do
        expect(page).not_to have_css('.gl-spinner')
      end
    end
  end

  context 'with ci status' do
    let(:ref) { 'master' }

    let_it_be(:user) { create(:user) }

    before do
      allow(view).to receive(:current_user).and_return(user)

      create(
        :ci_empty_pipeline,
        ref: 'master',
        sha: commit.id,
        status: 'success',
        project: project
      )
    end

    context 'when pipelines are disabled' do
      before do
        allow(project).to receive(:builds_enabled?).and_return(false)
      end

      it 'does not display a ci status icon' do
        render partial: template, formats: :html, locals: {
          project: project,
          ref: ref,
          commit: commit
        }

        expect(rendered).not_to have_css("[data-testid='ci-icon']")
      end
    end

    context 'when pipelines are enabled' do
      context 'when user has access' do
        before do
          project.add_developer(user)
        end

        it 'displays a ci status icon' do
          render partial: template, formats: :html, locals: {
            project: project,
            ref: ref,
            commit: commit
          }

          expect(rendered).to have_css("[data-testid='ci-icon']")
        end
      end

      context 'when user does not have access' do
        it 'does not display a ci status icon' do
          render partial: template, formats: :html, locals: {
            project: project,
            ref: ref,
            commit: commit
          }

          expect(rendered).not_to have_css("[data-testid='ci-icon']")
        end
      end
    end
  end

  it 'does not render history button' do
    allow(view).to receive(:project_commits_path).and_return('/commits/123')
    expect(rendered).not_to have_css('#js-commit-history-link')
  end

  context 'when it is blob page' do
    let(:ref) { 'master' }

    before do
      allow(view).to receive(:project_commits_path).and_return('/commits/123')
      render partial: template, formats: :html, locals: {
        project: project,
        ref: ref,
        commit: commit,
        is_blob_page: true
      }
    end

    it 'renders the history button' do
      expect(rendered).to have_css('#js-commit-history-link')
    end

    it 'only renders commit details when expanded' do
      expect(rendered).to have_selector('.js-toggle-content')
      within('.js-toggle-content') do
        expect(rendered).to have_selector('.commit-row-description')
        expect(rendered).to have_content(commit.short_id)
      end
    end
  end
end
