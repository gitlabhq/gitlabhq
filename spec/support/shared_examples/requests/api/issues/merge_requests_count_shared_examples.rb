# frozen_string_literal: true

def get_issue
  json_response.is_a?(Array) ? json_response.detect { |issue| issue['id'] == target_issue.id } : json_response
end

RSpec.shared_examples 'accessible merge requests count' do
  it 'returns anonymous accessible merge requests count' do
    get api(api_url), params: { scope: 'all' }

    issue = get_issue
    expect(issue).not_to be_nil
    expect(issue['merge_requests_count']).to eq(1)
  end

  it 'returns guest accessible merge requests count' do
    get api(api_url, guest), params: { scope: 'all' }

    issue = get_issue
    expect(issue).not_to be_nil
    expect(issue['merge_requests_count']).to eq(1)
  end

  it 'returns reporter accessible merge requests count' do
    get api(api_url, user), params: { scope: 'all' }

    issue = get_issue
    expect(issue).not_to be_nil
    expect(issue['merge_requests_count']).to eq(2)
  end

  it 'returns admin accessible merge requests count' do
    get api(api_url, admin), params: { scope: 'all' }

    issue = get_issue
    expect(issue).not_to be_nil
    expect(issue['merge_requests_count']).to eq(2)
  end
end
