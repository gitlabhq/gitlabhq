# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::NamespaceCommitEmail, type: :model, feature_category: :source_code_management do
  subject { build(:namespace_commit_email) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:email) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:email) }

    it { is_expected.to validate_uniqueness_of(:user).scoped_to(:namespace_id) }

    describe 'validate_root_group' do
      let_it_be(:root_group) { create(:group) }

      context 'when root group' do
        subject { build(:namespace_commit_email, namespace: root_group) }

        it { is_expected.to be_valid }
      end

      context 'when subgroup' do
        subject { build(:namespace_commit_email, namespace: create(:group, parent: root_group)) }

        it 'is invalid and reports the relevant error' do
          expect(subject).to be_invalid
          expect(subject.errors[:namespace]).to include('must be a root group.')
        end
      end
    end
  end

  it { is_expected.to be_valid }

  describe '.delete_for_namespace' do
    let_it_be(:group) { create(:group) }

    it 'deletes all records for namespace' do
      create_list(:namespace_commit_email, 3, namespace: group)
      create(:namespace_commit_email)

      expect { described_class.delete_for_namespace(group) }.to change { described_class.count }.by(-3)
    end
  end
end
