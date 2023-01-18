# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BranchRule, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:protected_branch) { create(:protected_branch, project: project, name: 'feature*') }

  subject { described_class.new(protected_branch.project, protected_branch) }

  it 'delegates methods to protected branch' do
    expect(subject).to delegate_method(:name).to(:protected_branch)
    expect(subject).to delegate_method(:group).to(:protected_branch)
    expect(subject).to delegate_method(:default_branch?).to(:protected_branch)
    expect(subject).to delegate_method(:created_at).to(:protected_branch)
    expect(subject).to delegate_method(:updated_at).to(:protected_branch)
  end

  it 'is protected' do
    expect(subject.protected?).to eq(true)
  end

  it 'branch protection returns protected branch' do
    expect(subject.branch_protection).to eq(protected_branch)
  end

  describe '#matching_branches_count' do
    it 'returns the number of branches that are matching the protected branch name' do
      expect(subject.matching_branches_count).to eq(2)
    end
  end
end
