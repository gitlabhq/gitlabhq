# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AwardEmojis::AddService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:awardable) { create(:note, project: project) }

  let(:name) { AwardEmoji::THUMBS_UP }

  subject(:service) { described_class.new(awardable, name, user) }

  describe '#execute' do
    context 'when user is not authorized' do
      it 'does not add an emoji' do
        expect { service.execute }.not_to change { AwardEmoji.count }
      end

      it 'returns an error state' do
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(:forbidden)
      end
    end

    context 'when user is authorized' do
      before do
        project.add_developer(user)
      end

      it 'creates an award emoji' do
        expect { service.execute }.to change { AwardEmoji.count }.by(1)
      end

      it 'returns the award emoji' do
        result = service.execute

        expect(result[:award]).to be_kind_of(AwardEmoji)
      end

      it 'return a success status' do
        result = service.execute

        expect(result[:status]).to eq(:success)
      end

      it 'sets the correct properties on the award emoji' do
        award = service.execute[:award]

        expect(award.name).to eq(name)
        expect(award.user).to eq(user)
      end

      it 'executes hooks' do
        expect(service).to receive(:execute_hooks).with(kind_of(AwardEmoji), 'award')

        service.execute
      end

      describe 'marking Todos as done' do
        subject { service.execute }

        include_examples 'creating award emojis marks Todos as done'
      end

      context 'when the awardable cannot have emoji awarded to it' do
        before do
          expect(awardable).to receive(:emoji_awardable?).and_return(false)
        end

        it 'does not add an emoji' do
          expect { service.execute }.not_to change { AwardEmoji.count }
        end

        it 'returns an error status' do
          result = service.execute

          expect(result[:status]).to eq(:error)
          expect(result[:http_status]).to eq(:unprocessable_entity)
        end
      end

      context 'when the awardable is invalid' do
        before do
          expect_next_instance_of(AwardEmoji) do |award|
            expect(award).to receive(:valid?).and_return(false)
            expect(award).to receive_message_chain(:errors, :full_messages).and_return(['Error 1', 'Error 2'])
          end
        end

        it 'does not add an emoji' do
          expect { service.execute }.not_to change { AwardEmoji.count }
        end

        it 'returns an error status' do
          result = service.execute

          expect(result[:status]).to eq(:error)
        end

        it 'returns an error message' do
          result = service.execute

          expect(result[:message]).to eq('Error 1 and Error 2')
        end
      end
    end
  end
end
