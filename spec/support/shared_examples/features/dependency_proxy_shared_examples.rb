# frozen_string_literal: true

RSpec.shared_examples 'a successful blob pull' do
  it 'sends a file' do
    expect(controller).to receive(:send_file).with(blob.file.path, {})

    subject
  end

  it 'returns Content-Disposition: attachment', :aggregate_failures do
    subject

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.headers['Content-Disposition']).to match(/^attachment/)
  end
end

RSpec.shared_examples 'a successful manifest pull' do
  it 'sends a file' do
    expect(controller).to receive(:send_file).with(manifest.file.path, { type: manifest.content_type })

    subject
  end

  it 'returns Content-Disposition: attachment', :aggregate_failures do
    subject

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.headers[DependencyProxy::Manifest::DIGEST_HEADER]).to eq(manifest.digest)
    expect(response.headers['Content-Length']).to eq(manifest.size)
    expect(response.headers['Docker-Distribution-Api-Version']).to eq(DependencyProxy::DISTRIBUTION_API_VERSION)
    expect(response.headers['Etag']).to eq("\"#{manifest.digest}\"")
    expect(response.headers['Content-Disposition']).to match(/^attachment/)
  end
end
