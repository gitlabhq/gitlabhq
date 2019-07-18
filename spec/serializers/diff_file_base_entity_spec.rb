# frozen_string_literal: true

require 'spec_helper'

describe DiffFileBaseEntity do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  context 'diff for a changed submodule' do
    let(:commit_sha_with_changed_submodule) do
      "cfe32cf61b73a0d5e9f13e774abde7ff789b1660"
    end
    let(:commit) { project.commit(commit_sha_with_changed_submodule) }
    let(:diff_file) { commit.diffs.diff_files.to_a.last }
    let(:options) { { request: {}, submodule_links: Gitlab::SubmoduleLinks.new(repository) } }
    let(:entity) { described_class.new(diff_file, options).as_json }

    it do
      expect(entity[:submodule]).to eq(true)
      expect(entity[:submodule_link]).to eq("https://github.com/randx/six")
      expect(entity[:submodule_tree_url]).to eq(
        "https://github.com/randx/six/tree/409f37c4f05865e4fb208c771485f211a22c4c2d"
      )
    end
  end
end
