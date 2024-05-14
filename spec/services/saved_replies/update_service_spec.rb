# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SavedReplies::UpdateService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:saved_reply) { create(:saved_reply, user: current_user) }
    let_it_be(:other_saved_reply) { create(:saved_reply, user: current_user) }
    let_it_be(:saved_reply_from_other_user) { create(:saved_reply) }

    subject(:service) { described_class.new(saved_reply: saved_reply, name: name, content: content).execute }

    context 'when update fails' do
      let(:name) { other_saved_reply.name }
      let(:content) { '' }

      it { expect(service[:status]).to eq(:error) }

      it 'returns error messages' do
        expect(service[:message]).to match_array(["Content can't be blank", "Name has already been taken"])
      end
    end

    context 'when update succeeds' do
      let(:name) { saved_reply_from_other_user.name }
      let(:content) { 'New content for Saved Reply' }

      it { expect(service[:status]).to eq(:success) }

      it 'updates new Saved Reply in database' do
        expect { service }.not_to change { ::Users::SavedReply.count }
      end

      it 'returns saved reply' do
        expect(service[:saved_reply]).to eq(saved_reply)
      end
    end
  end
end
