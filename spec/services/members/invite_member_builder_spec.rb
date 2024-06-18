# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteMemberBuilder, feature_category: :groups_and_projects do
  let_it_be(:source) { create(:group) }
  let_it_be(:existing_member) { create(:group_member) }

  let(:existing_members) { { existing_member.user.id => existing_member } }

  describe '#execute' do
    context 'when user record found by email' do
      it 'returns member from existing members hash' do
        expect(described_class.new(source, existing_member.user.email, existing_members).execute).to eq existing_member
      end

      it 'builds a new member' do
        user = create(:user)

        member = described_class.new(source, user.email, existing_members).execute

        expect(member).to be_new_record
        expect(member.user).to eq user
      end
    end
  end

  context 'when no existing users found by the email' do
    it 'finds existing member' do
      member = create(:group_member, :invited, source: source)

      expect(described_class.new(source, member.invite_email, existing_members).execute).to eq member
    end

    it 'builds a new member' do
      email = 'test@example.com'

      member = described_class.new(source, email, existing_members).execute

      expect(member).to be_new_record
      expect(member.invite_email).to eq email
    end
  end

  context 'with email downcase' do
    let_it_be(:email) { 'TEST@eXAMPle.com' }
    let(:invitee) { email }

    subject(:resulting_member) { described_class.new(source, invitee, {}).execute }

    it 'builds a new member and downcases the input' do
      expect(resulting_member).to be_new_record
      expect(resulting_member.invite_email).to eq 'test@example.com'
    end

    context 'with existing member' do
      before_all do
        create(:group_member, :invited, invite_email: email, source: source)
      end

      it 'finds the member with non downcased value' do
        expect(resulting_member).not_to be_new_record
        expect(resulting_member.invite_email).to eq email
      end

      context 'with downcased invite email input' do
        let(:invitee) { email.downcase }

        it 'does not find the existing member that has different casing' do
          expect(resulting_member).to be_new_record
          expect(resulting_member.invite_email).to eq invitee
        end
      end
    end
  end
end
