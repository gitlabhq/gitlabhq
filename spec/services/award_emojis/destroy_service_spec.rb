# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::DestroyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:awardable) { create(:note) }
  let_it_be(:project) { awardable.project }

  let(:name) { 'thumbsup' }
  let!(:award_from_other_user) do
    create(:award_emoji, name: name, awardable: awardable, user: create(:user))
  end

  subject(:service) { described_class.new(awardable, name, user) }

  describe '#execute' do
    shared_examples_for 'a service that does not authorize the user' do |error:|
      it 'does not remove the emoji' do
        expect { service.execute }.not_to change { AwardEmoji.count }
      end

      it 'returns an error state' do
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(:forbidden)
      end

      it 'returns a nil award' do
        result = service.execute

        expect(result).to have_key(:award)
        expect(result[:award]).to be_nil
      end

      it 'returns the error' do
        result = service.execute

        expect(result[:message]).to eq(error)
        expect(result[:errors]).to eq([error])
      end
    end

    context 'when user is not authorized' do
      it_behaves_like 'a service that does not authorize the user',
                      error: 'User cannot destroy emoji on the awardable'
    end

    context 'when the user is authorized' do
      before do
        project.add_developer(user)
      end

      context 'when user has not awarded an emoji to the awardable' do
        let!(:award_from_user) { create(:award_emoji, name: name, user: user) }

        it_behaves_like 'a service that does not authorize the user',
                         error: 'User has not awarded emoji of type thumbsup on the awardable'
      end

      context 'when user has awarded an emoji to the awardable' do
        let!(:award_from_user) { create(:award_emoji, name: name, awardable: awardable, user: user) }

        it 'removes the emoji' do
          expect { service.execute }.to change { AwardEmoji.count }.by(-1)
        end

        it 'returns a success status' do
          result = service.execute

          expect(result[:status]).to eq(:success)
        end

        it 'returns no errors' do
          result = service.execute

          expect(result).not_to have_key(:error)
          expect(result).not_to have_key(:errors)
        end

        it 'returns the destroyed award' do
          result = service.execute

          expect(result[:award]).to eq(award_from_user)
          expect(result[:award]).to be_destroyed
        end
      end
    end
  end
end
