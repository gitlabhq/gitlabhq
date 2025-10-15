# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/diffs/viewers/_text.html.haml', feature_category: :source_code_management do
  include DiffHelper

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Repository functionality requires real database objects
  let_it_be(:project) { create(:project, :repository) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate
  let(:repository) { project.repository }
  let(:commit) { project.commit }
  let(:diff_file) { commit.diffs.diff_files.first }
  let(:viewer) { diff_file.simple_viewer }

  context 'when diff contains only whitespace changes' do
    before do
      allow(diff_file).to receive_messages(whitespace_only?: true, diffable_text?: true)
      allow(view).to receive(:params_with_whitespace).and_return(
        controller: 'commit',
        action: 'show',
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        id: commit.id
      )
    end

    it 'shows whitespace-only message' do
      render partial: 'projects/diffs/viewers/text', locals: { viewer: viewer }

      expect(rendered).to have_content('File changed. Contains only whitespace changes.')
    end

    context 'when in commit controller context' do
      before do
        allow(view).to receive(:current_controller?).with(:commit).and_return(true)
        assign(:commit, commit)
      end

      it 'shows whitespace link' do
        render partial: 'projects/diffs/viewers/text', locals: { viewer: viewer }

        expect(rendered).to have_link(href: view.project_commit_path(project, commit.id, view.params_with_whitespace))
      end
    end

    context 'when not in commit controller context' do
      before do
        allow(view).to receive(:current_controller?).with(:commit).and_return(false)
      end

      it 'does not show whitespace link' do
        render partial: 'projects/diffs/viewers/text', locals: { viewer: viewer }

        expect(rendered).not_to have_link(href: view.project_commit_path(
          project,
          commit.id,
          view.params_with_whitespace
        ))
      end
    end
  end

  context 'when diff contains regular changes' do
    before do
      allow(diff_file).to receive(:whitespace_only?).and_return(false)
    end

    it 'renders the normal diff view' do
      render partial: 'projects/diffs/viewers/text', locals: { viewer: viewer }

      expect(rendered).not_to have_content('File changed. Contains only whitespace changes.')
    end
  end
end
