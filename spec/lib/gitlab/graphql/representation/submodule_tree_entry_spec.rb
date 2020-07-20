# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Representation::SubmoduleTreeEntry do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  describe '.decorate' do
    let(:submodules) { repository.tree.submodules }

    it 'returns array of SubmoduleTreeEntry' do
      entries = described_class.decorate(submodules, repository.tree)

      expect(entries.first).to be_a(described_class)

      expect(entries.map(&:web_url)).to contain_exactly(
        "https://gitlab.com/gitlab-org/gitlab-grack",
        "https://github.com/gitlabhq/gitlab-shell",
        "https://github.com/randx/six"
      )

      expect(entries.map(&:tree_url)).to contain_exactly(
        "https://gitlab.com/gitlab-org/gitlab-grack/-/tree/645f6c4c82fd3f5e06f67134450a570b795e55a6",
        "https://github.com/gitlabhq/gitlab-shell/tree/79bceae69cb5750d6567b223597999bfa91cb3b9",
        "https://github.com/randx/six/tree/409f37c4f05865e4fb208c771485f211a22c4c2d"
      )
    end
  end
end
