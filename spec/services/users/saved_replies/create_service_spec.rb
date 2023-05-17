# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::SavedReplies::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:saved_reply) { create(:saved_reply, user: current_user) }

    subject { described_class.new(current_user: current_user, name: name, content: content).execute }

    context 'when create fails' do
      let(:name) { saved_reply.name }
      let(:content) { '' }

      it { is_expected.not_to be_success }

      it 'does not create new Saved Reply in database' do
        expect { subject }.not_to change(::Users::SavedReply, :count)
      end

      it 'returns error messages' do
        expect(subject.errors).to match_array(["Content can't be blank", "Name has already been taken"])
      end
    end

    context 'when create succeeds' do
      let(:name) { 'new_saved_reply_name' }
      let(:content) { 'New content for Saved Reply' }

      it { is_expected.to be_success }

      it 'creates new Saved Reply in database' do
        expect { subject }.to change(::Users::SavedReply, :count).by(1)
      end

      it 'returns new saved reply', :aggregate_failures do
        expect(subject[:saved_reply]).to eq(::Users::SavedReply.last)
        expect(subject[:saved_reply].name).to eq(name)
        expect(subject[:saved_reply].content).to eq(content)
      end
    end
  end
end
