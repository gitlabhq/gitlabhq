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
end
