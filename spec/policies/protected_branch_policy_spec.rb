# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranchPolicy, feature_category: :source_code_management do
  let_it_be_with_refind(:user) { create(:user) }
  let_it_be(:protected_branch) { create(:protected_branch, name: 'feature') }
  let_it_be(:project) { protected_branch.project }

  subject { described_class.new(user, protected_branch) }

  context 'as a maintainer' do
    before_all do
      project.add_maintainer(user)
    end

    it_behaves_like 'allows protected branch crud'
  end

  context 'as a developer' do
    before_all do
      project.add_developer(user)
    end

    it_behaves_like 'disallows protected branch crud'
  end

  context 'as a guest' do
    before_all do
      project.add_guest(user)
    end

    it_behaves_like 'disallows protected branch crud'
  end
end
