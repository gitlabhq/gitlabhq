# frozen_string_literal: true

require 'spec_helper'

# We disabled main_branch_over_master feature for tests
# In order to have consistent branch usages
# When we migrate the branch name to main, we can enable it
RSpec.describe Gitlab::DefaultBranch do
  context 'main_branch_over_master is enabled' do
    before do
      stub_feature_flags(main_branch_over_master: true)
    end

    it 'returns main' do
      expect(described_class.value).to eq('main')
    end
  end

  context 'main_branch_over_master is disabled' do
    it 'returns master' do
      expect(described_class.value).to eq('master')
    end
  end
end
