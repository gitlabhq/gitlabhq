# frozen_string_literal: true

RSpec.shared_context 'with the container registry GitLab API returning tags' do
  let_it_be(:tags_response) do
    [
      {
        name: 'test',
        digest: 'sha256:6c3c647c6eebdaab7c610cf7d66709b3',
        size_bytes: 1234567892
      },
      {
        name: 'test2',
        digest: 'sha256:6c3c647c6eebdaab7c610cf7d66709b3',
        size_bytes: 1234567892
      }
    ]
  end

  let_it_be(:response_body) do
    {
      pagination: {},
      response_body: ::Gitlab::Json.parse(tags_response.to_json)
    }
  end
end
