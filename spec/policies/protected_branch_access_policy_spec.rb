# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranchAccessPolicy, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:protected_branch_access) { create(:protected_branch_merge_access_level) }
  let(:project) { protected_branch_access.protected_branch.project }

  subject { described_class.new(user, protected_branch_access) }

  context 'as maintainers' do
    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'allows protected branch crud'
  end

  context 'as guests' do
    before do
      project.add_guest(user)
    end

    it_behaves_like 'disallows protected branch crud'
  end
end
