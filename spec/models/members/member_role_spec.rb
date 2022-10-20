# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberRole do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to have_many(:members) }
  end

  describe 'validation' do
    subject { described_class.new }

    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:base_access_level) }

    context 'for namespace' do
      subject { build(:member_role) }

      let_it_be(:root_group) { create(:group) }

      context 'when namespace is a subgroup' do
        it 'is invalid' do
          subgroup = create(:group, parent: root_group)
          subject.namespace = subgroup

          expect(subject).to be_invalid
        end
      end

      context 'when namespace is a root group' do
        it 'is valid' do
          subject.namespace = root_group

          expect(subject).to be_valid
        end
      end

      context 'when namespace is not present' do
        it 'is invalid with a different error message' do
          subject.namespace = nil

          expect(subject).to be_invalid
          expect(subject.errors.full_messages).to eq(["Namespace can't be blank"])
        end
      end
    end
  end
end
