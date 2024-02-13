# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SavedReplies::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:saved_reply) { create(:saved_reply, user: current_user) }

    subject(:service) { described_class.new(object: current_user, name: name, content: content).execute }

    context 'when create fails' do
      let(:name) { saved_reply.name }
      let(:content) { '' }

      it { expect(service[:status]).to eq(:error) }

      it 'does not create new Saved Reply in database' do
        expect { service }.not_to change { ::Users::SavedReply.count }
      end

      it 'returns error messages' do
        expect(service[:message]).to match_array(["Content can't be blank", "Name has already been taken"])
      end
    end

    context 'when create succeeds' do
      let(:name) { 'new_saved_reply_name' }
      let(:content) { 'New content for Saved Reply' }

      it { expect(service[:status]).to eq(:success) }

      it 'creates new Saved Reply in database' do
        expect { service }.to change { ::Users::SavedReply.count }.by(1)
      end

      it 'returns new saved reply', :aggregate_failures do
        expect(service[:saved_reply]).to eq(::Users::SavedReply.last)
        expect(service[:saved_reply].name).to eq(name)
        expect(service[:saved_reply].content).to eq(content)
      end
    end
  end
end
