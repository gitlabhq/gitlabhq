# frozen_string_literal: true

RSpec.shared_examples 'rejects unsigned Workhorse upload metadata' do |verb|
  let(:canary) { "SECRET-CANARY-627748-%%%\n" }
  let(:secret_upload_path) { ::Repositories::CommitsUploader.workhorse_local_upload_path }
  let(:secret_file_path) { "#{secret_upload_path}/627748-secret-#{SecureRandom.hex(8)}.txt" }

  before do
    FileUtils.mkdir_p(secret_upload_path)
    File.write(secret_file_path, canary)
  end

  after do
    FileUtils.rm_f(secret_file_path)
  end

  it 'rejects unsigned file metadata without leaking local file information', :aggregate_failures do
    raw_params = {
      file: '',
      'file.path': secret_file_path,
      'file.size': 1,
      'Content-Type': 'application/x-www-form-urlencoded'
    }
    expect(UploadedFile).not_to receive(:new)

    process(verb, unsigned_upload_url, params: raw_params, headers: workhorse_headers)

    expect(response).to have_gitlab_http_status(:unauthorized)
    expect(response.body).not_to include(canary)

    process(verb, unsigned_upload_url, params: raw_params.merge('file.path': non_existing_file_path),
      headers: workhorse_headers)

    expect(response).to have_gitlab_http_status(:unauthorized)
    expect(response.body).not_to include('local file not present')
  end
end
