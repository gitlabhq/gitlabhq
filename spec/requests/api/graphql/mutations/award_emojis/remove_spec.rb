# frozen_string_literal: true

require 'spec_helper'

describe 'Removing an AwardEmoji' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:awardable) { create(:note) }
  let(:project) { awardable.project }
  let(:emoji_name) { 'thumbsup' }
  let(:input) { { awardable_id: GitlabSchema.id_from_object(awardable).to_s, name: emoji_name } }

  let(:mutation) do
    graphql_mutation(:remove_award_emoji, input)
  end

  def mutation_response
    graphql_mutation_response(:remove_award_emoji)
  end

  def create_award_emoji(user)
    create(:award_emoji, name: emoji_name, awardable: awardable, user: user )
  end

  shared_examples 'a mutation that does not destroy an AwardEmoji' do
    specify do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { AwardEmoji.count }
    end
  end

  shared_examples 'a mutation that does not authorize the user' do
    it_behaves_like 'a mutation that does not destroy an AwardEmoji'

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not exist or you don\'t have permission to perform this action']
  end

  context 'when the current_user does not own the award emoji' do
    let!(:award_emoji) { create_award_emoji(create(:user)) }

    it_behaves_like 'a mutation that does not authorize the user'
  end

  context 'when the current_user owns the award emoji' do
    let!(:award_emoji) { create_award_emoji(current_user) }

    context 'when the given awardable is not an Awardable' do
      let(:awardable) { create(:label) }

      it_behaves_like 'a mutation that does not destroy an AwardEmoji'

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: ['Cannot award emoji to this resource']
    end

    context 'when the given awardable is an Awardable' do
      it 'removes the emoji' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { AwardEmoji.count }.by(-1)
      end

      it 'returns no errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to be_nil
      end

      it 'returns an empty awardEmoji' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to have_key('awardEmoji')
        expect(mutation_response['awardEmoji']).to be_nil
      end
    end
  end
end
