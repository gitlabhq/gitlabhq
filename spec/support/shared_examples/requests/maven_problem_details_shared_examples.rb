# frozen_string_literal: true

RSpec.shared_examples 'returning RFC 9457 problem details' do |status:, detail: nil|
  it "returns RFC 9457 problem details with status #{status}" do
    subject

    status_code = Rack::Utils.status_code(status)

    expect(response).to have_gitlab_http_status(status)
    expect(response.content_type).to eq('application/problem+json')

    expect(json_response).to include(
      'type' => 'about:blank',
      'status' => status_code,
      'title' => Rack::Utils::HTTP_STATUS_CODES[status_code]
    )

    if detail
      expect(json_response['detail']).to eq(detail)
    else
      expect(json_response).not_to have_key('detail')
    end
  end
end

RSpec.shared_examples 'not returning RFC 9457 problem details' do |status:|
  it "returns standard error response with status #{status}" do
    subject

    expect(response).to have_gitlab_http_status(status)
    expect(response.content_type).not_to eq('application/problem+json')
    expect(json_response).to have_key('message')
  end
end
