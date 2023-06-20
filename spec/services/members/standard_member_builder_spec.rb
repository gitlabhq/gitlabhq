# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::StandardMemberBuilder, feature_category: :groups_and_projects do
  let_it_be(:source) { create(:group) }
  let_it_be(:existing_member) { create(:group_member) }

  let(:existing_members) { { existing_member.user.id => existing_member } }

  describe '#execute' do
    it 'returns member from existing members hash' do
      expect(described_class.new(source, existing_member.user, existing_members).execute).to eq existing_member
    end

    it 'builds a new member' do
      user = create(:user)

      member = described_class.new(source, user, existing_members).execute

      expect(member).to be_new_record
      expect(member.user).to eq user
    end
  end
end
