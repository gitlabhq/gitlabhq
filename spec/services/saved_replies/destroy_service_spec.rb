# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SavedReplies::DestroyService, feature_category: :team_planning do
  describe '#execute' do
    let!(:saved_reply) { create(:saved_reply) }

    subject(:service) { described_class.new(saved_reply: saved_reply).execute }

    context 'when destroy fails' do
      before do
        allow(saved_reply).to receive(:destroy).and_return(false)
      end

      it 'does not remove Saved Reply from database' do
        expect { service }.not_to change { ::Users::SavedReply.count }
      end

      it { expect(service[:status]).to eq(:error) }
    end

    context 'when destroy succeeds' do
      it { expect(service[:status]).to eq(:success) }

      it 'removes Saved Reply from database' do
        expect { service }.to change { ::Users::SavedReply.count }.by(-1)
      end

      it 'returns saved reply' do
        expect(service[:saved_reply]).to eq(saved_reply)
      end
    end
  end
end
