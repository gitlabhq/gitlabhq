# frozen_string_literal: true

RSpec.shared_examples 'rejects rubygems packages access' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'process rubygems workhorse authorization' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status

    it 'has the proper content type' do
      subject

      expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
    end

    context 'with a request that bypassed gitlab-workhorse' do
      let(:headers) do
        { 'HTTP_AUTHORIZATION' => personal_access_token.token }
          .merge(workhorse_headers)
          .tap { |h| h.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER) }
      end

      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'returning response status', :forbidden
    end
  end
end

RSpec.shared_examples 'process rubygems upload' do |user_type, status, add_member = true|
  RSpec.shared_examples 'creates rubygems package files' do
    it 'creates package files', :aggregate_failures do
      expect(::Packages::Rubygems::ExtractionWorker).to receive(:perform_async).with(an_instance_of(Integer)).once

      expect { subject }
          .to change { project.packages.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)

      package = project.packages.last
      expect(package).not_to be_nil

      package_file = package.package_files.reload.last
      expect(package_file).not_to be_nil

      expect(package_file.file_name).to eq('package.gem')

      expect(response).to have_gitlab_http_status(status)
    end

    it 'returns bad request if package creation fails' do
      error_response = ServiceResponse.error(message: 'Package creation failed', reason: :bad_request)
      package_file_service_double = instance_double(::Packages::Rubygems::CreatePackageFileService, execute: error_response)

      expect(::Packages::Rubygems::CreatePackageFileService).to receive(:new).and_return(package_file_service_double)

      subject

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'does not enqueue a background job if the transaction is rolled back' do
      expect(::Packages::Rubygems::CreatePackageFileService).to receive(:new).and_raise(ActiveRecord::RecordNotFound)
      expect(::Packages::Rubygems::ExtractionWorker).not_to receive(:perform_async)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    context 'with object storage disabled' do
      before do
        stub_package_file_object_storage(enabled: false)
      end

      context 'without a file from workhorse' do
        let(:send_rewritten_field) { false }

        it_behaves_like 'returning response status', :bad_request
      end

      context 'with correct params' do
        it_behaves_like 'package workhorse uploads'
        it_behaves_like 'creates rubygems package files'
        it_behaves_like 'a package tracking event', 'API::RubygemPackages', 'push_package'
      end
    end

    context 'with object storage enabled' do
      let(:tmp_object) do
        fog_connection.directories.new(key: 'packages').files.create( # rubocop:disable Rails/SaveBang
          key: "tmp/uploads/#{file_name}",
          body: 'content'
        )
      end

      let(:fog_file) { fog_to_uploaded_file(tmp_object) }
      let(:params) { { file: fog_file, 'file.remote_id' => file_name } }

      context 'and direct upload enabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: true)
        end

        it_behaves_like 'creates rubygems package files'

        ['123123', '../../123123'].each do |remote_id|
          context "with invalid remote_id: #{remote_id}" do
            let(:params) do
              {
                file: fog_file,
                'file.remote_id' => remote_id
              }
            end

            it_behaves_like 'returning response status', :forbidden
          end
        end
      end

      context 'and direct upload disabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: false)
        end

        it_behaves_like 'creates rubygems package files'
      end
    end
  end
end

RSpec.shared_examples 'dependency endpoint success' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    raise 'Status is not :success' if status != :success

    context 'with no params', :aggregate_failures do
      it 'returns empty' do
        subject

        expect(response.body).to eq('200')
        expect(response).to have_gitlab_http_status(status)
      end
    end

    context 'with gems params' do
      let(:params) { { gems: 'foo,bar' } }
      let(:expected_response) { Marshal.dump(%w[result result]) }

      it 'returns successfully', :aggregate_failures do
        service_result = double('DependencyResolverService', execute: ServiceResponse.success(payload: 'result'))

        expect(Packages::Rubygems::DependencyResolverService).to receive(:new).with(project, anything, gem_name: 'foo').and_return(service_result)
        expect(Packages::Rubygems::DependencyResolverService).to receive(:new).with(project, anything, gem_name: 'bar').and_return(service_result)

        subject

        expect(response.body).to eq(expected_response)
        expect(response).to have_gitlab_http_status(status)
      end

      it 'rejects if the service fails', :aggregate_failures do
        service_result = double('DependencyResolverService', execute: ServiceResponse.error(message: 'rejected', http_status: :bad_request))

        expect(Packages::Rubygems::DependencyResolverService).to receive(:new).with(project, anything, gem_name: 'foo').and_return(service_result)

        subject

        expect(response.body).to match(/rejected/)
        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end

RSpec.shared_examples 'Rubygems gem download' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it 'returns the gem', :aggregate_failures do
      subject

      expect(response.media_type).to eq('application/octet-stream')
      expect(response).to have_gitlab_http_status(status)
    end

    it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
    it_behaves_like 'bumping the package last downloaded at field'
  end
end
