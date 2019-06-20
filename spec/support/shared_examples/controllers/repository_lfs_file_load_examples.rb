# frozen_string_literal: true

# Shared examples for controllers that load and send files from the git repository
# (like Projects::RawController or Projects::AvatarsController)

# These examples requires the following variables:
# - `project`
# - `filename`: filename of the file
# - `filepath`: path of the file (contains filename)
# - `subject`: the request to be made to the controller. Example:
# subject { get :show, namespace_id: project.namespace, project_id: project }
#
# The LFS disabled scenario can be skipped by passing `skip_lfs_disabled_tests: true`
# when including the examples (Note, at time of writing this is only used by
# an EE-specific spec):
#
# it_behaves_like 'a controller that can serve LFS files', skip_lfs_disabled_tests: true do
#   ...
# end
shared_examples 'a controller that can serve LFS files' do |options = {}|
  let(:lfs_oid) { '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897' }
  let(:lfs_size) { '1575078' }
  let!(:lfs_object) { create(:lfs_object, oid: lfs_oid, size: lfs_size) }

  context 'when lfs is enabled' do
    before do
      allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(true)
    end

    context 'when project has access' do
      before do
        project.lfs_objects << lfs_object
        allow_any_instance_of(LfsObjectUploader).to receive(:exists?).and_return(true)
        allow(controller).to receive(:send_file) { controller.head :ok }
      end

      it 'serves the file' do
        lfs_uploader = LfsObjectUploader.new(lfs_object)

        # Notice the filename= is omitted from the disposition; this is because
        # Rails 5 will append this header in send_file
        expect(controller).to receive(:send_file)
                          .with(
                            File.join(lfs_uploader.root, lfs_uploader.store_dir, lfs_uploader.filename),
                            filename: filename,
                            disposition: %Q(attachment; filename*=UTF-8''#{filename}))

        subject

        expect(response).to have_gitlab_http_status(200)
      end

      context 'and lfs uses object storage' do
        let(:lfs_object) { create(:lfs_object, :with_file, oid: lfs_oid, size: lfs_size) }

        before do
          stub_lfs_object_storage
          lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)
        end

        it 'responds with redirect to file' do
          subject

          expect(response).to have_gitlab_http_status(302)
          expect(response.location).to include(lfs_object.reload.file.path)
        end

        it 'sets content disposition' do
          subject

          file_uri = URI.parse(response.location)
          params = CGI.parse(file_uri.query)

          expect(params["response-content-disposition"].first).to eq(%Q(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
        end
      end
    end

    context 'when project does not have access' do
      it 'does not serve the file' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  context 'when lfs is not enabled' do
    before do
      allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(false)
    end

    it 'delivers ASCII file' do
      skip 'Calling spec asked to skip testing LFS disabled scenario' if options[:skip_lfs_disabled_tests]

      subject

      expect(response).to have_gitlab_http_status(200)
      expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')
      expect(response.header['Content-Disposition'])
          .to eq('inline')
      expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
    end
  end
end
