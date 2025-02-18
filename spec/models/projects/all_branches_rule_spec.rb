# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AllBranchesRule, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  subject(:all_branches_rule) { described_class.new(project) }

  describe '::find(id)' do
    context 'when id matches a Project' do
      it 'finds the project and initializes a branch rule' do
        instance = described_class.find(project.id)
        expect(instance).to be_instance_of(described_class)
        expect(instance.project.id).to eq(project.id)
      end
    end

    context 'when id does not match a Project' do
      it 'raises an ActiveRecord::RecordNotFound error describing the branch rule' do
        expect { described_class.find(0) }.to raise_error(
          ActiveRecord::RecordNotFound, "Couldn't find Projects::AllBranchesRule with 'id'=0"
        )
      end
    end
  end

  describe '#id' do
    it { is_expected.to delegate_method(:id).to(:project) }
  end

  describe '#to_global_id' do
    it 'generates a valid global id' do
      expect(all_branches_rule.to_global_id.to_s).to eq("gid://gitlab/Projects::AllBranchesRule/#{project.id}")
    end
  end

  describe '#name' do
    it 'set to All branches' do
      expect(all_branches_rule.name).to eq('All branches')
    end
  end

  describe '#group' do
    it 'returns nil' do
      expect(all_branches_rule.group).to be_nil
    end
  end

  describe '#default_branch?' do
    it { is_expected.not_to be_default_branch }
  end

  describe '#protected?' do
    it { is_expected.not_to be_protected }
  end

  describe '#branch_protection' do
    it 'returns nil' do
      expect(all_branches_rule.branch_protection).to be_nil
    end
  end

  describe '#created_at' do
    it 'returns nil' do
      expect(all_branches_rule.created_at).to be_nil
    end
  end

  describe '#updated_at' do
    it 'returns nil' do
      expect(all_branches_rule.updated_at).to be_nil
    end
  end

  describe '#squash_option' do
    it 'returns a squash option based on project settings' do
      expect(all_branches_rule.squash_option.squash_option).to eq(project.project_setting.squash_option)
    end
  end
end
