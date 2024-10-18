# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::AwardEmoji, feature_category: :team_planning do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:unauthorized_user) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: reporter) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:current_user) { reporter }

  describe '#before_update' do
    subject do
      described_class.new(issuable: work_item, current_user: current_user, params: params)
        .before_update
    end

    shared_examples 'raises a callback error' do
      it { expect { subject }.to raise_error(::Issuable::Callbacks::Base::Error, message) }
    end

    context 'when awarding an emoji' do
      let(:params) { { action: :add, name: 'star' } }

      context 'when user has no access' do
        let(:current_user) { unauthorized_user }

        it 'does not award the emoji' do
          expect { subject }.not_to change { AwardEmoji.count }
        end
      end

      context 'when user has access' do
        it 'awards the emoji to the work item' do
          expect { subject }.to change { AwardEmoji.count }.by(1)

          emoji = AwardEmoji.last

          expect(emoji.name).to eq('star')
          expect(emoji.awardable_id).to eq(work_item.id)
          expect(emoji.user).to eq(current_user)
        end

        context 'when the name is incorrect' do
          let(:params) { { action: :add, name: 'foo' } }

          it_behaves_like 'raises a callback error' do
            let(:message) { 'Name is not a valid emoji name' }
          end
        end

        context 'when the action is incorrect' do
          let(:params) { { action: :foo, name: 'star' } }

          it_behaves_like 'raises a callback error' do
            let(:message) { 'foo is not a valid action.' }
          end
        end
      end
    end

    context 'when removing emoji' do
      let(:params) { { action: :remove, name: AwardEmoji::THUMBS_UP } }

      context 'when user has no access' do
        let(:current_user) { unauthorized_user }

        it 'does not remove the emoji' do
          expect { subject }.not_to change { AwardEmoji.count }
        end
      end

      context 'when user has access' do
        it 'removes existing emoji' do
          create(:award_emoji, :upvote, awardable: work_item, user: current_user)

          expect { subject }.to change { AwardEmoji.count }.by(-1)
        end

        context 'when work item does not have the emoji' do
          let(:params) { { action: :remove, name: 'star' } }

          it_behaves_like 'raises a callback error' do
            let(:message) { 'User has not awarded emoji of type star on the awardable' }
          end
        end
      end
    end
  end
end
