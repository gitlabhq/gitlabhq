# frozen_string_literal: true

RSpec.shared_examples 'Debian packages GET request' do |status, body = nil|
  and_body = body.nil? ? '' : ' and expected body'

  it "returns #{status}#{and_body}" do
    subject

    expect(response).to have_gitlab_http_status(status)

    unless body.nil?
      expect(response.body).to match(body)
    end
  end
end

RSpec.shared_examples 'Debian packages upload request' do |status, body = nil|
  and_body = body.nil? ? '' : ' and expected body'

  if status == :created
    it 'creates package files', :aggregate_failures do
      expect(::Packages::Debian::CreatePackageFileService).to receive(:new).with(package: be_a(Packages::Package), current_user: be_an(User), params: be_an(Hash)).and_call_original

      if extra_params[:distribution] || file_name.end_with?('.changes')
        expect(::Packages::Debian::FindOrCreateIncomingService).not_to receive(:new)
        expect(::Packages::Debian::ProcessPackageFileWorker).to receive(:perform_async).with(be_a(Integer), extra_params[:distribution], extra_params[:component])
        expect { subject }
          .to change { container.packages.debian.count }.by(1)
          .and not_change { container.packages.debian.where(name: 'incoming').count }
          .and change { container.package_files.count }.by(1)
      else
        expect(::Packages::Debian::FindOrCreateIncomingService).to receive(:new).with(container, user).and_call_original
        expect(::Packages::Debian::ProcessPackageFileWorker).not_to receive(:perform_async)

        expect { subject }
          .to change { container.packages.debian.count }.by(1)
          .and change { container.packages.debian.where(name: 'incoming').count }.by(1)
          .and change { container.package_files.count }.by(1)
      end

      expect(response).to have_gitlab_http_status(status)
      expect(response.media_type).to eq('text/plain')

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  else
    it "returns #{status}#{and_body}", :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  end
end

RSpec.shared_examples 'Debian packages upload authorize request' do |status, body = nil|
  and_body = body.nil? ? '' : ' and expected body'

  if status == :created
    it 'authorizes package file upload', :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(json_response['TempPath']).to eq(Packages::PackageFileUploader.workhorse_local_upload_path)
      expect(json_response['RemoteObject']).to be_nil
      expect(json_response['MaximumSize']).to be_nil
    end

    context 'without a valid token' do
      let(:workhorse_token) { 'invalid' }

      it 'rejects request' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'bypassing gitlab-workhorse' do
      let(:workhorse_headers) { {} }

      it 'rejects request' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  else
    it "returns #{status}#{and_body}", :aggregate_failures do
      subject

      expect(response).to have_gitlab_http_status(status)

      unless body.nil?
        expect(response.body).to match(body)
      end
    end
  end
end

RSpec.shared_examples 'Debian packages read endpoint' do |desired_behavior, success_status, success_body|
  context 'with valid container' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_type, :auth_method, :expected_status, :expected_body) do
      :public  | :guest         | :basic         | success_status | success_body
      :public  | :not_a_member  | :basic         | success_status | success_body
      :public  | :anonymous     | :basic         | success_status | success_body
      :public  | :invalid_token | :basic         | :unauthorized  | nil
      :private | :developer     | :basic         | success_status | success_body
      :private | :developer     | :private_token | :unauthorized  | nil
      :private | :guest         | :basic         | success_status | success_body
      :private | :not_a_member  | :basic         | :not_found     | nil
      :private | :anonymous     | :basic         | :unauthorized  | nil
      :private | :invalid_token | :basic         | :unauthorized  | nil
    end

    with_them do
      include_context 'Debian repository access', params[:visibility_level], params[:user_type], params[:auth_method] do
        it_behaves_like "Debian packages #{desired_behavior} request", params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown container id', :unauthorized, :basic
end

RSpec.shared_examples 'Debian packages write endpoint' do |desired_behavior, success_status, success_body|
  context 'with valid container' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :user_type, :auth_method, :expected_status, :expected_body) do
      :public  | :developer     | :basic         | success_status | success_body
      :public  | :developer     | :private_token | :unauthorized  | nil
      :public  | :guest         | :basic         | :forbidden     | nil
      :public  | :not_a_member  | :basic         | :forbidden     | nil
      :public  | :anonymous     | :basic         | :unauthorized  | nil
      :public  | :invalid_token | :basic         | :unauthorized  | nil
      :private | :developer     | :basic         | success_status | success_body
      :private | :guest         | :basic         | :forbidden     | nil
      :private | :not_a_member  | :basic         | :not_found     | nil
      :private | :anonymous     | :basic         | :unauthorized  | nil
      :private | :invalid_token | :basic         | :unauthorized  | nil
    end

    with_them do
      include_context 'Debian repository access', params[:visibility_level], params[:user_type], params[:auth_method] do
        it_behaves_like "Debian packages #{desired_behavior} request", params[:expected_status], params[:expected_body]
      end
    end
  end

  it_behaves_like 'rejects Debian access with unknown container id', :unauthorized, :basic
end

RSpec.shared_examples 'Debian packages endpoint catching ObjectStorage::RemoteStoreError' do
  include_context 'Debian repository access', :public, :developer, :basic do
    it "returns forbidden" do
      expect(::Packages::Debian::CreatePackageFileService).to receive(:new).and_raise ObjectStorage::RemoteStoreError

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end

RSpec.shared_examples 'Debian packages index endpoint' do |success_body|
  it_behaves_like 'Debian packages read endpoint', 'GET', :success, success_body

  context 'when no ComponentFile is found' do
    let(:target_component_name) { component.name + FFaker::Lorem.word }

    it_behaves_like 'Debian packages read endpoint', 'GET', :no_content, /^$/
  end
end

RSpec.shared_examples 'Debian packages index sha256 endpoint' do |success_body|
  it_behaves_like 'Debian packages read endpoint', 'GET', :success, success_body

  context 'with empty checksum' do
    let(:target_sha256) { 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' }

    it_behaves_like 'Debian packages read endpoint', 'GET', :no_content, /^$/
  end

  context 'when ComponentFile is not found' do
    let(:target_component_name) { component.name + FFaker::Lorem.word }

    it_behaves_like 'Debian packages read endpoint', 'GET', :not_found, /^{"message":"404 Not Found"}$/
  end
end
