# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AcceptInviteService, feature_category: :user_management do
  let_it_be(:user) { create(:user, email: 'user1@example.com') }
  let_it_be(:error) { 'The invitation could not be accepted.' }

  let(:member) { create(:project_member, :invited, invite_email: user.email) }

  subject(:service) { described_class.new(user, member: member) }

  describe '#execute' do
    context 'with different user and member emails' do
      let(:member) { create(:project_member, :invited, invite_email: 'user2@example.com') }

      it 'returns an error response' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq error
      end

      it 'does not connect the member and the user' do
        expect { service.execute }.not_to change { member.user }
      end

      it 'does not publish an event' do
        expect(Gitlab::EventStore).not_to receive(:publish)

        service.execute
      end
    end

    context 'with failing acceptation' do
      before do
        allow(member).to receive(:accept_invite!).with(user).and_return(false)
      end

      it 'returns an error response' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq error
      end

      it 'does not connect the member and the user' do
        expect { service.execute }.not_to change { member.user }
      end

      it 'does not publish an event' do
        expect(Gitlab::EventStore).not_to receive(:publish)

        service.execute
      end
    end

    context 'with successful acceptation' do
      let(:event) { Members::AcceptedInviteEvent.new(data: data) }
      let(:data) do
        {
          member_id: member.id,
          source_id: member.source_id,
          source_type: member.source_type,
          user_id: user.id
        }
      end

      it { expect(service.execute).to be_success }

      it 'connects the member and the user' do
        expect { service.execute }.to change { member.user }.from(nil).to(user)
      end

      it { expect { service.execute }.to publish_event(Members::AcceptedInviteEvent).with(data) }
    end
  end
end
