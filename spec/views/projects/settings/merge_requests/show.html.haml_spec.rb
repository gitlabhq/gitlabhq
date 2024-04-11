# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/merge_requests/show', feature_category: :code_review_workflow do
  include Devise::Test::ControllerHelpers
  include ProjectForksHelper

  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive_messages(
      current_user: user,
      can?: true,
      current_application_settings: Gitlab::CurrentSettings.current_application_settings
    )
  end

  describe 'merge suggestions settings' do
    it 'displays a placeholder if none is set' do
      render

      placeholder = "Apply %{suggestions_count} suggestion(s) to %{files_count} file(s)\n\n%{co_authored_by}"

      expect(rendered).to have_field('project[suggestion_commit_message]', placeholder: placeholder)
    end

    it 'displays the user entered value' do
      project.update!(suggestion_commit_message: 'refactor: changed %{file_paths}')

      render

      expect(rendered).to have_field('project[suggestion_commit_message]', with: 'refactor: changed %{file_paths}')
    end
  end

  describe 'merge commit template' do
    it 'displays default template if none is set' do
      render

      expect(rendered).to have_field('project[merge_commit_template_or_default]', with: <<~MSG.rstrip)
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{title}

        %{issues}

        See merge request %{reference}
      MSG
    end

    it 'displays the user entered value' do
      project.update!(merge_commit_template: '%{title}')

      render

      expect(rendered).to have_field('project[merge_commit_template_or_default]', with: '%{title}')
    end
  end

  describe 'squash template' do
    it 'displays default template if none is set' do
      render

      expect(rendered).to have_field('project[squash_commit_template_or_default]', with: '%{title}')
    end

    it 'displays the user entered value' do
      project.update!(squash_commit_template: '%{first_multiline_commit}')

      render

      expect(rendered).to have_field('project[squash_commit_template_or_default]', with: '%{first_multiline_commit}')
    end
  end
end
