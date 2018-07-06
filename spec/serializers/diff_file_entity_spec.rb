require 'spec_helper'

describe DiffFileEntity do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff_refs) { commit.diff_refs }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: diff_refs, repository: repository) }
  let(:entity) { described_class.new(diff_file, request: {}) }

  subject { entity.as_json }

  shared_examples 'diff file entity' do
    it 'exposes correct attributes' do
      expect(subject).to include(
        :submodule, :submodule_link, :submodule_tree_url, :file_path,
        :deleted_file, :old_path, :new_path, :mode_changed,
        :a_mode, :b_mode, :text, :old_path_html,
        :new_path_html, :highlighted_diff_lines, :parallel_diff_lines,
        :blob, :file_hash, :added_lines, :removed_lines, :diff_refs, :content_sha,
        :stored_externally, :external_storage, :too_large, :collapsed, :new_file,
        :context_lines_path
      )
    end

    # Converted diff files from GitHub import does not contain blob file
    # and content sha.
    context 'when diff file does not have a blob and content sha' do
      it 'exposes some attributes as nil' do
        allow(diff_file).to receive(:content_sha).and_return(nil)
        allow(diff_file).to receive(:blob).and_return(nil)

        expect(subject[:context_lines_path]).to be_nil
        expect(subject[:view_path]).to be_nil
        expect(subject[:highlighted_diff_lines]).to be_nil
        expect(subject[:can_modify_blob]).to be_nil
      end
    end
  end

  context 'when there is no merge request' do
    it_behaves_like 'diff file entity'
  end

  context 'when there is a merge request' do
    let(:user) { create(:user) }
    let(:request) { EntityRequest.new(project: project, current_user: user) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let(:entity) { described_class.new(diff_file, request: request, merge_request: merge_request) }
    let(:exposed_urls) { %i(load_collapsed_diff_url edit_path view_path context_lines_path) }

    it_behaves_like 'diff file entity'

    it 'exposes additional attributes' do
      expect(subject).to include(*exposed_urls)
      expect(subject).to include(:replaced_view_path)
    end

    it 'points all urls to merge request target project' do
      response = subject

      exposed_urls.each do |attribute|
        expect(response[attribute]).to include(merge_request.target_project.to_param)
      end
    end
  end
end
