# frozen_string_literal: true

require 'spec_helper'

describe 'projects/commits/_commit.html.haml' do
  let(:template) { 'projects/commits/commit.html.haml' }
  let(:project) { create(:project, :repository) }
  let(:commit) { project.repository.commit(ref) }

  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
  end

  context 'with a signed commit' do
    let(:ref) { GpgHelpers::SIGNED_COMMIT_SHA }

    it 'does not display a loading spinner for GPG status' do
      render partial: template, locals: {
        project: project,
        ref: ref,
        commit: commit
      }

      within '.gpg-status-box' do
        expect(page).not_to have_css('i.fa.fa-spinner.fa-spin')
      end
    end
  end

  context 'with ci status' do
    let(:ref) { 'master' }
    let(:user) { create(:user) }

    before do
      allow(view).to receive(:current_user).and_return(user)

      project.add_developer(user)

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
        render partial: template, locals: {
          project: project,
          ref: ref,
          commit: commit
        }

        expect(rendered).not_to have_css('.ci-status-link')
      end
    end

    context 'when pipelines are enabled' do
      before do
        allow(project).to receive(:builds_enabled?).and_return(true)
      end

      it 'does display a ci status icon when pipelines are enabled' do
        render partial: template, locals: {
          project: project,
          ref: ref,
          commit: commit
        }

        expect(rendered).to have_css('.ci-status-link')
      end
    end
  end
end
