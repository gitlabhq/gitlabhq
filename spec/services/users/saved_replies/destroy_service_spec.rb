# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SavedReplies::DestroyService, feature_category: :team_planning do
  describe '#execute' do
    let!(:saved_reply) { create(:saved_reply) }

    subject { described_class.new(saved_reply: saved_reply).execute }

    context 'when destroy fails' do
      before do
        allow(saved_reply).to receive(:destroy).and_return(false)
      end

      it 'does not remove Saved Reply from database' do
        expect { subject }.not_to change(::Users::SavedReply, :count)
      end

      it { is_expected.not_to be_success }
    end

    context 'when destroy succeeds' do
      it { is_expected.to be_success }

      it 'removes Saved Reply from database' do
        expect { subject }.to change(::Users::SavedReply, :count).by(-1)
      end

      it 'returns saved reply' do
        expect(subject[:saved_reply]).to eq(saved_reply)
      end
    end
  end
end
