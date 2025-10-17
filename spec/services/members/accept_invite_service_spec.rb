# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AcceptInviteService, feature_category: :user_management do
  let_it_be(:user) { create(:user, email: 'user1@example.com') }
  let_it_be(:error) { 'The invitation could not be accepted.' }

  let(:member) { create(:project_member, :invited, invite_email: user.email) }
  let(:service) { described_class.new(user, member: member) }

  subject(:result) { service.execute }

  describe '#execute' do
    context 'with different user and member emails' do
      let(:member) { create(:project_member, :invited, invite_email: 'user2@example.com') }

      it 'returns an error response' do
        expect(result).to be_error
        expect(result.message).to eq error
      end

      it 'does not connect the member and the user' do
        expect { result }.not_to change { member.user }
      end
    end

    context 'with failing acceptation' do
      before do
        allow(member).to receive(:accept_invite!).with(user).and_return(false)
      end

      it 'returns an error response' do
        expect(result).to be_error
        expect(result.message).to eq error
      end

      it 'does not connect the member and the user' do
        expect { result }.not_to change { member.user }
      end
    end

    context 'with successful acceptation' do
      it 'returns a success response' do
        expect(result).to be_success
      end

      it 'connects the member and the user' do
        expect { result }.to change { member.user }.from(nil).to(user)
      end
    end
  end
end
