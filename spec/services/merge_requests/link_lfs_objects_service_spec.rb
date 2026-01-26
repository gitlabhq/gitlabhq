# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::LinkLfsObjectsService, :sidekiq_inline, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:target_project) { create(:project, :public, :repository) }
  let_it_be(:source_project) { fork_project(target_project, user, namespace: user.namespace, repository: true) }

  let(:lfs_enabled) { true }
  let(:link_service) { instance_spy(Projects::LfsPointers::LfsLinkService) }
  let(:merge_request) do
    create(
      :merge_request,
      target_project: target_project,
      target_branch: 'lfs',
      source_project: source_project,
      source_branch: 'link-lfs-objects'
    )
  end

  subject(:service) { described_class.new(project: target_project) }

  before do
    stub_config(lfs: { enabled: lfs_enabled })

    allow(target_project).to receive(:lfs_enabled?).and_return(lfs_enabled)

    allow(Projects::LfsPointers::LfsLinkService)
      .to receive(:new).with(target_project)
      .and_return(link_service)

    ::Branches::CreateService.new(source_project, user).execute('link-lfs-objects', 'lfs')
  end

  shared_examples_for 'linking LFS objects' do
    shared_examples_for 'does not initialize a link service' do
      it 'does not initialize LfsLinkService' do
        execute

        expect(Projects::LfsPointers::LfsLinkService).not_to have_received(:new)
      end
    end

    context 'when there are valid LFS objects added' do
      before do
        create_file_in_repo(source_project, 'link-lfs-objects', 'link-lfs-objects', 'one.lfs', 'One')
        create_file_in_repo(source_project, 'link-lfs-objects', 'link-lfs-objects', 'two.lfs', 'Two')
      end

      it 'calls Projects::LfsPointers::LfsLinkService#execute with OIDs of LFS objects in merge request' do
        execute

        expect(link_service).to have_received(:execute).with(%w[
          8b12507783d5becacbf2ebe5b01a60024d8728a8f86dcc818bce699e8b3320bc
          94a72c074cfe574742c9e99e863322f73feff82981d065ff65a0308f44f19f62
        ])
      end

      context 'when merge request is not for a fork' do
        let(:source_project) { target_project }

        it_behaves_like 'does not initialize a link service'
      end

      context 'when LFS is disabled' do
        let(:lfs_enabled) { false }

        it_behaves_like 'does not initialize a link service'
      end

      context 'when there are no changes' do
        before do
          allow(service).to receive(:no_changes?).and_return(true)
        end

        it_behaves_like 'does not initialize a link service'
      end

      context 'when there are LFS objects that do not belong to the source project' do
        before do
          allow_next_instance_of(Gitlab::Git::LfsChanges) do |instance|
            allow(instance).to receive(:new_pointers)
              .and_return([
                instance_double(Gitlab::Git::Blob, lfs_oid: "8b12507783d5becacbf2ebe5b01a60024d8728a8f86dcc818bce699e8b3320bc"),
                instance_double(Gitlab::Git::Blob, lfs_oid: "94a72c074cfe574742c9e99e863322f73feff82981d065ff65a0308f44f19f62"),
                instance_double(Gitlab::Git::Blob, lfs_oid: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa") # this LFS object doesn't belong to the source project
              ])
          end
        end

        it 'only links LFS objects that belong to the source project' do
          execute

          expect(link_service).to have_received(:execute).with(%w[
            8b12507783d5becacbf2ebe5b01a60024d8728a8f86dcc818bce699e8b3320bc
            94a72c074cfe574742c9e99e863322f73feff82981d065ff65a0308f44f19f62
          ])
        end

        context 'when batch size is 2' do
          before do
            stub_const("#{described_class}::BATCH_SIZE", 2)

            allow(source_project).to receive(:valid_lfs_oids).and_call_original
          end

          it 'calls valid_lfs_oids method two times when BATCH_SIZE is 2' do
            execute

            expect(source_project).to have_received(:valid_lfs_oids).twice
          end
        end
      end
    end

    context 'when no LFS objects added' do
      before do
        create_file_in_repo(source_project, 'link-lfs-objects', 'link-lfs-objects', 'one.txt', 'One')
      end

      it_behaves_like 'does not initialize a link service'
    end
  end

  context 'when no oldrev and newrev passed' do
    subject(:execute) { service.execute(merge_request) }

    it_behaves_like 'linking LFS objects'
  end

  context 'when oldrev and newrev are passed' do
    subject(:execute) { service.execute(merge_request, oldrev: merge_request.diff_base_sha, newrev: merge_request.diff_head_sha) }

    it_behaves_like 'linking LFS objects'
  end
end
