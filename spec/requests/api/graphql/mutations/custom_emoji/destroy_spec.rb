# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deletion of custom emoji', feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be_with_reload(:custom_emoji) { create(:custom_emoji, group: group, creator: user2) }

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(custom_emoji).to_s
    }

    graphql_mutation(:destroy_custom_emoji, variables)
  end

  shared_examples 'does not delete custom emoji' do
    it 'does not change count' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(CustomEmoji, :count)
    end
  end

  shared_examples 'deletes custom emoji' do
    it 'changes count' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.to change(CustomEmoji, :count).by(-1)
    end
  end

  context 'when the user' do
    context 'has no permissions' do
      it_behaves_like 'does not delete custom emoji'
    end

    context 'when the user is developer and not creator of custom emoji' do
      before do
        group.add_developer(current_user)
      end

      it_behaves_like 'does not delete custom emoji'
    end
  end

  context 'when user' do
    context 'is maintainer' do
      before do
        group.add_maintainer(current_user)
      end

      it_behaves_like 'deletes custom emoji'
    end

    context 'is owner' do
      before do
        group.add_owner(current_user)
      end

      it_behaves_like 'deletes custom emoji'
    end

    context 'is developer and creator of the emoji' do
      before do
        group.add_developer(current_user)
        custom_emoji.update_attribute(:creator, current_user)
      end

      it_behaves_like 'deletes custom emoji'
    end
  end
end
