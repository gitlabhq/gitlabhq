shared_examples 'a 404 response when source is private' do
  before do
    source.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
  end

  it 'returns 404' do
    route

    expect(response).to have_gitlab_http_status(404)
  end
end
