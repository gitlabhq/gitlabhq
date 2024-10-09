# frozen_string_literal: true

RSpec.shared_examples 'Endpoint not found if read_model_registry not available' do
  context 'when read_model_registry disabled for current project' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(user, :read_model_registry, project)
                          .and_return(false)
    end

    context 'when file has path' do
      let(:file_path) { 'my_dir/' }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when file does not have path' do
      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end

RSpec.shared_examples 'Endpoint not found if write_model_registry not available' do
  context 'when write_model_registry is disabled for current project' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(user, :write_model_registry, project)
                          .and_return(false)
    end

    context 'when file has path' do
      let(:file_path) { 'my_dir/' }

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when file does not have path' do
      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end

RSpec.shared_examples 'Not found when model version does not exist' do
  context 'when model version does not exist' do
    let(:version_id) { non_existing_record_id }

    it { is_expected.to have_gitlab_http_status(:not_found) }
  end
end

RSpec.shared_examples 'creates package files for model versions' do
  it 'creates package files', :aggregate_failures do
    expect { api_response }
      .to change { Packages::PackageFile.count }.by(1)
    expect(api_response).to have_gitlab_http_status(:created)

    package_file = project.packages.last.package_files.reload.last
    expect(package_file.file_name).to eq(saved_file_name)
  end

  it_behaves_like 'a package tracking event', 'API::MlModelPackages', 'push_package'

  it 'returns bad request if package creation fails' do
    expect_next_instance_of(::Packages::MlModel::CreatePackageFileService) do |instance|
      expect(instance).to receive(:execute).and_return(nil)
    end

    expect(api_response).to have_gitlab_http_status(:bad_request)
  end

  context 'when file is too large' do
    it 'is bad request', :aggregate_failures do
      allow_next_instance_of(UploadedFile) do |uploaded_file|
        allow(uploaded_file).to receive(:size).and_return(project.actual_limits.ml_model_max_file_size + 1)
      end

      expect(api_response).to have_gitlab_http_status(:bad_request)
    end
  end
end

RSpec.shared_examples 'process ml model package upload' do
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
      it_behaves_like 'creates package files for model versions'
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

      it_behaves_like 'creates package files for model versions'

      ['123123', '../../123123'].each do |remote_id|
        context "with invalid remote_id: #{remote_id}" do
          let(:params) do
            {
              file: fog_file,
              'file.remote_id' => remote_id
            }
          end

          it { is_expected.to have_gitlab_http_status(:forbidden) }
        end
      end
    end

    context 'and direct upload disabled' do
      let(:fog_connection) do
        stub_package_file_object_storage(direct_upload: false)
      end

      it_behaves_like 'creates package files for model versions'
    end
  end
end

RSpec.shared_examples 'process ml model package download' do
  context 'when package file exists' do
    it { is_expected.to have_gitlab_http_status(:success) }
  end

  it_behaves_like 'a package tracking event', 'API::MlModelPackages', 'pull_package'
  it_behaves_like 'Not found when model version does not exist'
end
