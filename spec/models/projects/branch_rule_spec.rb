# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BranchRule, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:protected_branch) { create(:protected_branch, project: project, name: 'feature*') }

  subject { described_class.new(protected_branch.project, protected_branch) }

  describe '::find(id)' do
    context 'when id matches a Project' do
      it 'finds the project and initializes a branch rule' do
        instance = described_class.find(protected_branch.id)
        expect(instance).to be_instance_of(described_class)
        expect(instance.protected_branch.id).to eq(protected_branch.id)
        expect(instance.project.id).to eq(project.id)
      end
    end

    context 'when id does not match a Project' do
      it 'raises an ActiveRecord::RecordNotFound error describing the branch rule' do
        expect { described_class.find(0) }.to raise_error(
          ActiveRecord::RecordNotFound, "Couldn't find Projects::BranchRule with 'id'=0"
        )
      end
    end
  end

  it 'generates a valid global id' do
    expect(subject.to_global_id.to_s).to eq("gid://gitlab/Projects::BranchRule/#{protected_branch.id}")
  end

  it 'delegates methods to protected branch' do
    expect(subject).to delegate_method(:id).to(:protected_branch)
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
