# frozen_string_literal: true

require 'spec_helper'

describe DiffFileBaseEntity do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:entity) { described_class.new(diff_file, options).as_json }

  context 'diff for a changed submodule' do
    let(:commit_sha_with_changed_submodule) do
      "cfe32cf61b73a0d5e9f13e774abde7ff789b1660"
    end
    let(:commit) { project.commit(commit_sha_with_changed_submodule) }
    let(:options) { { request: {}, submodule_links: Gitlab::SubmoduleLinks.new(repository) } }
    let(:diff_file) { commit.diffs.diff_files.to_a.last }

    it do
      expect(entity[:submodule]).to eq(true)
      expect(entity[:submodule_link]).to eq("https://github.com/randx/six")
      expect(entity[:submodule_tree_url]).to eq(
        "https://github.com/randx/six/tree/409f37c4f05865e4fb208c771485f211a22c4c2d"
      )
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
    let(:options) { { request: EntityRequest.new(current_user: create(:user)), merge_request: merge_request } }
    let(:params) { {} }

    before do
      stub_feature_flags(web_ide_default: false)
    end

    shared_examples 'a diff file edit path to the source branch' do
      it do
        expect(entity[:edit_path]).to eq(Gitlab::Routing.url_helpers.project_edit_blob_path(project, File.join(merge_request.source_branch, diff_file.new_path), params))
      end
    end

    context 'open' do
      let(:merge_request) { create(:merge_request, source_project: project, target_branch: 'master', source_branch: 'feature') }
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
end
