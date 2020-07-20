# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ForcePush do
  let_it_be(:project) { create(:project, :repository) }

  describe '.force_push?' do
    it 'returns false if the repo is empty' do
      allow(project).to receive(:empty_repo?).and_return(true)

      expect(described_class.force_push?(project, 'HEAD', 'HEAD~')).to be(false)
    end

    it 'checks if old rev is an anchestor' do
      expect(described_class.force_push?(project, 'HEAD', 'HEAD~')).to be(true)
    end
  end
end
