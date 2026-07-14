# frozen_string_literal: true

module WikiHelpers
  extend self
  def stub_group_wikis(enabled)
    stub_licensed_features(group_wikis: enabled)
  end

  def upload_file_to_wiki(wiki, user, file_name)
    params = {
      file_name: file_name,
      file_content: File.read(expand_fixture_path(file_name))
    }

    ::Wikis::CreateAttachmentService.new(
      container: wiki.container,
      current_user: user,
      params: params
    ).execute.dig(:result, :file_path)
  end

  def save_changes(commit_message = nil)
    submit_form("Save changes", commit_message)
  end

  def create_page(commit_message = nil)
    submit_form("Create page", commit_message)
  end

  def create_sidebar(commit_message = nil)
    submit_form("Create sidebar", commit_message)
  end

  def submit_form(save_button_text, commit_message = nil)
    click_on save_button_text

    within_testid('commit-message-modal') do
      fill_in(:wiki_message, with: commit_message) unless commit_message.nil?
      click_on save_button_text
    end
  end
end
