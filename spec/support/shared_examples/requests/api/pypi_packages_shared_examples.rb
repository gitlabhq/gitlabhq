# frozen_string_literal: true

RSpec.shared_examples 'PyPI package creation' do |user_type, status, add_member = true|
  RSpec.shared_examples 'creating pypi package files' do
    it 'creates package files' do
      expect { subject }
          .to change { project.packages.pypi.count }.by(1)
          .and change { Packages::PackageFile.count }.by(1)
          .and change { Packages::Pypi::Metadatum.count }.by(1)
      expect(response).to have_gitlab_http_status(status)

      package = project.reload.packages.pypi.last

      expect(package.name).to eq params[:name]
      expect(package.version).to eq params[:version]
      expect(package.pypi_metadatum.required_python).to eq params[:requires_python]
    end
  end

  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'creating pypi package files'

    context 'with a pre-existing file' do
      it 'rejects the duplicated file' do
        existing_package = create(:pypi_package, name: base_params[:name], version: base_params[:version], project: project)
        create(:package_file, :pypi, package: existing_package, file_name: params[:content].original_filename)

        expect { subject }
            .to change { project.packages.pypi.count }.by(0)
            .and change { Packages::PackageFile.count }.by(0)
            .and change { Packages::Pypi::Metadatum.count }.by(0)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
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
        it_behaves_like 'creating pypi package files'
        it_behaves_like 'a package tracking event', described_class.name, 'push_package'
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
      let(:params) { base_params.merge(content: fog_file, 'content.remote_id' => file_name) }

      context 'and direct upload enabled' do
        let(:fog_connection) do
          stub_package_file_object_storage(direct_upload: true)
        end

        it_behaves_like 'creating pypi package files'

        ['123123', '../../123123'].each do |remote_id|
          context "with invalid remote_id: #{remote_id}" do
            let(:params) { base_params.merge(content: fog_file, 'content.remote_id' => remote_id) }

            it_behaves_like 'returning response status', :forbidden
          end
        end
      end

      context 'and direct upload disabled' do
        context 'and background upload disabled' do
          let(:fog_connection) do
            stub_package_file_object_storage(direct_upload: false, background_upload: false)
          end

          it_behaves_like 'creating pypi package files'
        end

        context 'and background upload enabled' do
          let(:fog_connection) do
            stub_package_file_object_storage(direct_upload: false, background_upload: true)
          end

          it_behaves_like 'creating pypi package files'
        end
      end
    end

    it_behaves_like 'background upload schedules a file migration'
  end
end

RSpec.shared_examples 'PyPI package versions' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it 'returns the package listing' do
      subject

      expect(response.body).to match(package.package_files.first.file_name)
    end

    it_behaves_like 'returning response status', status
    it_behaves_like 'a package tracking event', described_class.name, 'list_package'
  end
end

RSpec.shared_examples 'PyPI package download' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it 'returns the package listing' do
      subject

      expect(response.body).to eq(File.open(package.package_files.first.file.path, "rb").read)
    end

    it_behaves_like 'returning response status', status
    it_behaves_like 'a package tracking event', described_class.name, 'pull_package'
  end
end

RSpec.shared_examples 'process PyPI api request' do |user_type, status, add_member = true|
  context "for user type #{user_type}" do
    before do
      project.send("add_#{user_type}", user) if add_member && user_type != :anonymous
    end

    it_behaves_like 'returning response status', status
  end
end

RSpec.shared_examples 'rejects PyPI access with unknown project id' do
  context 'with an unknown project' do
    let(:project) { OpenStruct.new(id: 1234567890) }

    context 'as anonymous' do
      it_behaves_like 'process PyPI api request', :anonymous, :not_found
    end

    context 'as authenticated user' do
      subject { get api(url), headers: basic_auth_header(user.username, personal_access_token.token) }

      it_behaves_like 'process PyPI api request', :anonymous, :not_found
    end
  end
end
