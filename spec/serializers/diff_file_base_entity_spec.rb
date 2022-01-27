# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffFileBaseEntity do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:repository) { project.repository }
  let(:entity) { described_class.new(diff_file, options).as_json }

  shared_examples 'nil if removed source branch' do |key|
    before do
      allow(merge_request).to receive(:source_branch_exists?).and_return(false)
    end

    specify do
      expect(entity[key]).to eq(nil)
    end
  end

  context 'submodule information for a' do
    let(:commit_sha) { "" }
    let(:commit) { project.commit(commit_sha) }
    let(:options) { { request: {}, submodule_links: Gitlab::SubmoduleLinks.new(repository) } }
    let(:diff_file) { commit.diffs.diff_files.to_a.last }

    context 'newly added submodule' do
      let(:commit_sha) { "cfe32cf61b73a0d5e9f13e774abde7ff789b1660" }

      it 'says it is a submodule and contains links' do
        expect(entity[:submodule]).to eq(true)
        expect(entity[:submodule_link]).to eq("https://github.com/randx/six")
        expect(entity[:submodule_tree_url]).to eq(
          "https://github.com/randx/six/tree/409f37c4f05865e4fb208c771485f211a22c4c2d"
        )
      end

      it 'has no compare url because the submodule was newly added' do
        expect(entity[:submodule_compare]).to eq(nil)
      end
    end

    context 'changed submodule' do
      # Test repo does not contain a commit that changes a submodule, so we have create such a commit here
      let(:commit_sha) { repository.update_submodule(project.members[0].user, "six", "c6bc3aa2ee76cadaf0cbd325067c55450997632e", message: "Go one commit back", branch: "master") }

      it 'contains a link to compare the changes' do
        expect(entity[:submodule_compare]).to eq(
          {
            url: "https://github.com/randx/six/compare/409f37c4f05865e4fb208c771485f211a22c4c2d...c6bc3aa2ee76cadaf0cbd325067c55450997632e",
            old_sha: "409f37c4f05865e4fb208c771485f211a22c4c2d",
            new_sha: "c6bc3aa2ee76cadaf0cbd325067c55450997632e"
          }
        )
      end
    end

    context 'normal file (no submodule)' do
      let(:commit_sha) { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }

      it 'sets submodule to false' do
        expect(entity[:submodule]).to eq(false)
        expect(entity[:submodule_compare]).to eq(nil)
      end
    end
  end

  context 'contains raw sizes for the blob' do
    let(:commit) { project.commit('png-lfs') }
    let(:options) { { request: {} } }
    let(:diff_file) { commit.diffs.diff_files.to_a.second }

    it do
      expect(entity[:old_size]).to eq(1219696)
      expect(entity[:new_size]).to eq(132)
    end
  end

  context 'edit_path' do
    let(:diff_file) { merge_request.diffs.diff_files.to_a.last }
    let(:options) { { request: EntityRequest.new(current_user: user), merge_request: merge_request } }
    let(:params) { {} }

    shared_examples 'a diff file edit path to the source branch' do
      it do
        expect(entity[:edit_path]).to eq(Gitlab::Routing.url_helpers.project_edit_blob_path(project, File.join(merge_request.source_branch, diff_file.new_path), params))
      end
    end

    context 'open' do
      let(:merge_request) { create(:merge_request, source_project: project, target_branch: 'master', source_branch: 'feature') }
      let(:params) { { from_merge_request_iid: merge_request.iid } }

      it_behaves_like 'a diff file edit path to the source branch'
      it_behaves_like 'nil if removed source branch', :edit_path
    end

    context 'closed' do
      let(:merge_request) { create(:merge_request, source_project: project, state: :closed, target_branch: 'master', source_branch: 'feature') }
      let(:params) { { from_merge_request_iid: merge_request.iid } }

      it_behaves_like 'a diff file edit path to the source branch'

      context 'removed source branch' do
        before do
          allow(merge_request).to receive(:source_branch_exists?).and_return(false)
        end

        it do
          expect(entity[:edit_path]).to eq(nil)
        end
      end
    end

    context 'merged' do
      let(:merge_request) { create(:merge_request, source_project: project, state: :merged) }

      it do
        expect(entity[:edit_path]).to eq(Gitlab::Routing.url_helpers.project_edit_blob_path(project, File.join(merge_request.target_branch, diff_file.new_path), {}))
      end
    end
  end

  context 'ide_edit_path' do
    let(:source_project) { project }
    let(:merge_request) { create(:merge_request, iid: 123, target_project: target_project, source_project: source_project) }
    let(:diff_file) { merge_request.diffs.diff_files.to_a.last }
    let(:options) { { request: EntityRequest.new(current_user: user), merge_request: merge_request } }
    let(:expected_merge_request_path) { "/-/ide/project/#{source_project.full_path}/merge_requests/#{merge_request.iid}" }

    context 'when source_project and target_project are the same' do
      let(:target_project) { source_project }

      it_behaves_like 'nil if removed source branch', :ide_edit_path

      it 'returns the merge_request ide route' do
        expect(entity[:ide_edit_path]).to eq expected_merge_request_path
      end
    end

    context 'when source_project and target_project are different' do
      let(:target_project) { fork_project(source_project, source_project.first_owner, repository: true) }

      it 'returns the merge_request ide route with the target_project as param' do
        expect(entity[:ide_edit_path]).to eq("#{expected_merge_request_path}?target_project=#{ERB::Util.url_encode(target_project.full_path)}")
      end
    end
  end
end
