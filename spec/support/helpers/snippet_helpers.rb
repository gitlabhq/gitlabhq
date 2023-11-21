# frozen_string_literal: true

module SnippetHelpers
  def sign_in_as(user)
    sign_in(public_send(user)) if user
  end

  def snippet_blob_file(blob)
    {
      "path" => blob.path,
      "raw_url" => gitlab_raw_snippet_blob_url(blob.container, blob.path, host: Gitlab.config.gitlab.host)
    }
  end
end
