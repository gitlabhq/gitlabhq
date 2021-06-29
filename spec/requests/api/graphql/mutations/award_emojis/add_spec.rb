# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding an AwardEmoji' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:awardable) { create(:note, project: project) }

  let(:emoji_name) { 'thumbsup' }
  let(:mutation) do
    variables = {
      awardable_id: GitlabSchema.id_from_object(awardable).to_s,
      name: emoji_name
    }

    graphql_mutation(:award_emoji_add, variables)
  end

  def mutation_response
    graphql_mutation_response(:award_emoji_add)
  end

  shared_examples 'a mutation that does not create an AwardEmoji' do
    specify do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { AwardEmoji.count }
    end
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that does not create an AwardEmoji'
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the user has permission' do
    before do
      project.add_developer(current_user)
    end

    context 'when the given awardable is not an Awardable' do
      let(:awardable) { create(:label, project: project) }

      it_behaves_like 'a mutation that does not create an AwardEmoji'

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) { include(/was provided invalid value for awardableId/) }
      end
    end

    context 'when the given awardable is an Awardable but still cannot be awarded an emoji' do
      let(:awardable) { create(:system_note, project: project) }

      it_behaves_like 'a mutation that does not create an AwardEmoji'

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['You cannot award emoji to this resource.']
    end

    context 'when the given awardable is an Awardable' do
      it 'creates an emoji' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { AwardEmoji.count }.by(1)
      end

      it 'returns the emoji' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['awardEmoji']['name']).to eq(emoji_name)
      end

      describe 'marking Todos as done' do
        let(:user) { current_user}

        subject { post_graphql_mutation(mutation, current_user: user) }

        include_examples 'creating award emojis marks Todos as done'
      end

      context 'when there were active record validation errors' do
        before do
          expect_next_instance_of(AwardEmoji) do |award|
            expect(award).to receive(:valid?).at_least(:once).and_return(false)
            expect(award).to receive_message_chain(
              :errors,
              :full_messages
            ).and_return(['Error 1', 'Error 2'])
          end
        end

        it_behaves_like 'a mutation that does not create an AwardEmoji'

        it_behaves_like 'a mutation that returns errors in the response', errors: ['Error 1', 'Error 2']

        it 'returns an empty awardEmoji' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response).to have_key('awardEmoji')
          expect(mutation_response['awardEmoji']).to be_nil
        end
      end
    end
  end
end
