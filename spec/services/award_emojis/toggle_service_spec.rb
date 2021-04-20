# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::ToggleService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:awardable) { create(:note, project: project) }

  let(:name) { 'thumbsup' }

  subject(:service) { described_class.new(awardable, name, user) }

  describe '#execute' do
    context 'when user has awarded an emoji' do
      let!(:award_from_other_user) { create(:award_emoji, name: name, awardable: awardable, user: create(:user)) }
      let!(:award) { create(:award_emoji, name: name, awardable: awardable, user: user) }

      it 'calls AwardEmojis::DestroyService' do
        expect(AwardEmojis::AddService).not_to receive(:new)

        expect_next_instance_of(AwardEmojis::DestroyService) do |service|
          expect(service).to receive(:execute)
        end

        service.execute
      end

      it 'destroys an AwardEmoji' do
        expect { service.execute }.to change { AwardEmoji.count }.by(-1)
      end

      it 'returns the result of DestroyService#execute' do
        mock_result = double(foo: true)

        expect_next_instance_of(AwardEmojis::DestroyService) do |service|
          expect(service).to receive(:execute).and_return(mock_result)
        end

        result = service.execute

        expect(result).to eq(mock_result)
      end
    end

    context 'when user has not awarded an emoji' do
      it 'calls AwardEmojis::AddService' do
        expect_next_instance_of(AwardEmojis::AddService) do |service|
          expect(service).to receive(:execute)
        end

        expect(AwardEmojis::DestroyService).not_to receive(:new)

        service.execute
      end

      it 'creates an AwardEmoji' do
        expect { service.execute }.to change { AwardEmoji.count }.by(1)
      end

      it 'returns the result of AddService#execute' do
        mock_result = double(foo: true)

        expect_next_instance_of(AwardEmojis::AddService) do |service|
          expect(service).to receive(:execute).and_return(mock_result)
        end

        result = service.execute

        expect(result).to eq(mock_result)
      end
    end
  end
end
