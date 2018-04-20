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

  it 'exposes correct attributes' do
    expect(subject).to include(
      :submodule, :submodule_link, :file_path,
      :deleted_file, :old_path, :new_path, :mode_changed,
      :a_mode, :b_mode, :text, :old_path_html,
      :new_path_html
    )
  end
end
