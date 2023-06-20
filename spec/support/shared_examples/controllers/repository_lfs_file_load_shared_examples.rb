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
RSpec.shared_examples 'a controller that can serve LFS files' do |options = {}|
  let(:lfs_oid) { '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897' }
  let(:lfs_size) { '1575078' }
  let!(:lfs_object) { create(:lfs_object, oid: lfs_oid, size: lfs_size) }

  context 'when lfs is enabled' do
    before do
      allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(true)
      allow_any_instance_of(LfsObjectUploader).to receive(:exists?).and_return(true)
      allow(controller).to receive(:send_file) { controller.head :ok }
    end

    def link_project(project)
      project.lfs_objects << lfs_object
    end

    context 'when the project is linked to the LfsObject' do
      before do
        link_project(project)
      end

      it 'serves the file' do
        lfs_uploader = LfsObjectUploader.new(lfs_object)

        expect(controller).to receive(:send_file)
                          .with(
                            File.join(lfs_uploader.root, lfs_uploader.store_dir, lfs_uploader.filename),
                            {
                              filename: filename,
                              disposition: 'attachment'
                            })

        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'and lfs uses object storage' do
        let(:lfs_object) { create(:lfs_object, :with_file, oid: lfs_oid, size: lfs_size) }

        before do
          stub_lfs_object_storage
          lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)
        end

        it 'responds with redirect to file' do
          subject

          expect(response).to have_gitlab_http_status(:found)
          expect(response.location).to include(lfs_object.reload.file.path)
        end

        it 'sets content disposition' do
          subject

          file_uri = URI.parse(response.location)
          params = CGI.parse(file_uri.query)

          expect(params["response-content-disposition"].first).to eq(%(attachment; filename="#{filename}"; filename*=UTF-8''#{filename}))
        end
      end
    end

    context 'when project is not linked to the LfsObject' do
      it 'does not serve the file' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the project is part of a fork network' do
      shared_examples 'a controller that correctly serves lfs files within a fork network' do
        it do
          expect(fork_network_member).not_to eq(fork_network.root_project)
        end

        it 'does not serve the file if no members are linked to the LfsObject' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'serves the file when the fork network root is linked to the LfsObject' do
          link_project(fork_network.root_project)

          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'serves the file when the fork network member is linked to the LfsObject' do
          link_project(fork_network_member)

          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the project is the root of the fork network' do
        let!(:fork_network) { create(:fork_network, root_project: project) }
        let!(:fork_network_member) { create(:fork_network_member, fork_network: fork_network).project }

        before do
          project.reload
        end

        it_behaves_like 'a controller that correctly serves lfs files within a fork network'
      end

      context 'when the project is a downstream member of the fork network' do
        let!(:fork_network) { create(:fork_network) }
        let!(:fork_network_member) do
          create(:fork_network_member, project: project, fork_network: fork_network)
          project
        end

        before do
          project.reload
        end

        it_behaves_like 'a controller that correctly serves lfs files within a fork network'
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

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')
      expect(response.header['Content-Disposition'])
          .to eq('inline')
      expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
    end
  end
end
