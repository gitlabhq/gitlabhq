# frozen_string_literal: true

RSpec.shared_context 'bulk imports requests context' do |url|
  let(:page_response_headers) do
    {
      'Content-Type' => 'application/json',
      'X-Next-Page' => 2,
      'X-Page' => 1,
      'X-Per-Page' => 20,
      'X-Total' => 42,
      'X-Total-Pages' => 2
    }
  end

  let(:request_headers) { { 'Content-Type' => 'application/json' } }

  before do
    stub_request(:get, "#{url}/api/v4/version?private_token=demo-pat")
      .with(headers: request_headers)
      .to_return(
        status: 200,
        body: { version: ::BulkImport.min_gl_version_for_project_migration.to_s }.to_json,
        headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, "https://gitlab.example.com/api/v4/groups?min_access_level=50&page=1&per_page=20&private_token=demo-pat&search=test&top_level_only=true")
      .to_return(
        status: 200,
        body: [{
          id: 2595440,
          web_url: 'https://gitlab.com/groups/test',
          name: 'Test',
          path: 'stub-test-group',
          full_name: 'Test',
          full_path: 'stub-test-group'
        }].to_json,
        headers: page_response_headers
      )

    stub_request(:get, "%{url}/api/v4/groups?min_access_level=50&page=1&per_page=20&private_token=demo-pat&search=&top_level_only=true" % { url: url })
      .to_return(
        body: [{
          id: 2595438,
          web_url: 'https://gitlab.com/groups/auto-breakfast',
          name: 'Stub',
          path: 'stub-group',
          full_name: 'Stub',
          full_path: 'stub-group'
        }].to_json,
        headers: page_response_headers
      )
  end
end
