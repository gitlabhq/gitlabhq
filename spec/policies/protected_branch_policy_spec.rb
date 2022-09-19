# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranchPolicy do
  let(:user) { create(:user) }
  let(:name) { 'feature' }
  let(:protected_branch) { create(:protected_branch, name: name) }
  let(:project) { protected_branch.project }

  subject { described_class.new(user, protected_branch) }

  context 'as maintainers' do
    before do
      project.add_maintainer(user)
    end

    it 'can be read' do
      is_expected.to be_allowed(:read_protected_branch)
    end

    it 'can be created' do
      is_expected.to be_allowed(:create_protected_branch)
    end

    it 'can be updated' do
      is_expected.to be_allowed(:update_protected_branch)
    end

    it 'can be destroyed' do
      is_expected.to be_allowed(:destroy_protected_branch)
    end
  end

  context 'as guests' do
    before do
      project.add_guest(user)
    end

    it 'can be read' do
      is_expected.to be_disallowed(:read_protected_branch)
    end

    it 'can be created' do
      is_expected.to be_disallowed(:create_protected_branch)
    end

    it 'can be updated' do
      is_expected.to be_disallowed(:update_protected_branch)
    end

    it 'cannot be destroyed' do
      is_expected.to be_disallowed(:destroy_protected_branch)
    end
  end
end
