# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::LinkLfsObjectsService, :sidekiq_inline, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include RepoHelpers

  let(:target_project) { create(:project, :public, :repository) }

  let(:merge_request) do
    create(
      :merge_request,
      target_project: target_project,
      target_branch: 'lfs',
      source_project: source_project,
      source_branch: 'link-lfs-objects'
    )
  end

  subject { described_class.new(project: target_project) }

  shared_examples_for 'linking LFS objects' do
    context 'when source project is the same as target project' do
      let(:source_project) { target_project }

      it 'does not call Projects::LfsPointers::LfsLinkService#execute' do
        expect(Projects::LfsPointers::LfsLinkService).not_to receive(:new)

        execute
      end
    end

    context 'when source project is different from target project' do
      let(:user) { create(:user) }
      let(:source_project) { fork_project(target_project, user, namespace: user.namespace, repository: true) }

      before do
        create_branch(source_project, 'link-lfs-objects', 'lfs')
      end

      context 'and there are changes' do
        before do
          allow(source_project).to receive(:lfs_enabled?).and_return(true)
        end

        context 'and there are LFS objects added' do
          before do
            create_file_in_repo(source_project, 'link-lfs-objects', 'link-lfs-objects', 'one.lfs', 'One')
            create_file_in_repo(source_project, 'link-lfs-objects', 'link-lfs-objects', 'two.lfs', 'Two')
          end

          it 'calls Projects::LfsPointers::LfsLinkService#execute with OIDs of LFS objects in merge request' do
            expect_next_instance_of(Projects::LfsPointers::LfsLinkService) do |service|
              expect(service).to receive(:execute).with(
                %w[
                  8b12507783d5becacbf2ebe5b01a60024d8728a8f86dcc818bce699e8b3320bc
                  94a72c074cfe574742c9e99e863322f73feff82981d065ff65a0308f44f19f62
                ])
            end

            execute
          end
        end

        context 'but there are no LFS objects added' do
          before do
            create_file_in_repo(source_project, 'link-lfs-objects', 'link-lfs-objects', 'one.txt', 'One')
          end

          it 'does not call Projects::LfsPointers::LfsLinkService#execute' do
            expect(Projects::LfsPointers::LfsLinkService).not_to receive(:new)

            execute
          end
        end
      end

      context 'and there are no changes' do
        it 'does not call Projects::LfsPointers::LfsLinkService#execute' do
          expect(Projects::LfsPointers::LfsLinkService).not_to receive(:new)

          execute
        end
      end
    end
  end

  context 'when no oldrev and newrev passed' do
    let(:execute) { subject.execute(merge_request) }

    it_behaves_like 'linking LFS objects'
  end

  context 'when oldrev and newrev are passed' do
    let(:execute) { subject.execute(merge_request, oldrev: merge_request.diff_base_sha, newrev: merge_request.diff_head_sha) }

    it_behaves_like 'linking LFS objects'
  end

  def create_branch(project, new_name, branch_name)
    ::Branches::CreateService.new(project, user).execute(new_name, branch_name)
  end
end
