# Specs for paginated resources.
#
# Requires an API request:
#   let(:request) { get api("/projects/#{project.id}/repository/branches", user) }
shared_examples 'a paginated resources' do
  before do
    # Fires the request
    request
  end

  it 'has pagination headers' do
    expect(response.headers).to include('X-Total')
    expect(response.headers).to include('X-Total-Pages')
    expect(response.headers).to include('X-Per-Page')
    expect(response.headers).to include('X-Page')
    expect(response.headers).to include('X-Next-Page')
    expect(response.headers).to include('X-Prev-Page')
    expect(response.headers).to include('Link')
  end
end
