# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscribe to a wiki page', feature_category: :wiki do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:wiki_page_meta) { create(:wiki_page_meta, container: project) }

  let(:subscribed_state) { true }
  let(:mutation_input) { { 'id' => wiki_page_meta.to_global_id.to_s, 'subscribed' => subscribed_state } }
  let(:mutation) { graphql_mutation(:wikiPageSubscribe, mutation_input, fields) }
  let(:mutation_response) { graphql_mutation_response(:wiki_page_subscribe) }
  let(:fields) do
    <<~FIELDS
      wikiPage {
        subscribed
      }
      errors
    FIELDS
  end

  context 'when user is not allowed to update subscription wiki pages' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  shared_examples 'sets the subscription to the wiki pages notifications', :aggregate_failures do |setting|
    it 'successfully adds the subscription' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { wiki_page_meta.subscribed?(current_user, project) }
        .to(setting)

      expect(response).to have_gitlab_http_status(:success)

      expect(mutation_response['wikiPage']).to include({
        'subscribed' => setting
      })
    end
  end

  context 'when user has permissions to update its subscription to the wiki pages' do
    let(:current_user) { guest }

    include_examples 'sets the subscription to the wiki pages notifications', true

    context 'when unsubscribing' do
      let(:subscribed_state) { false }

      before do
        create(:subscription, project: project, user: current_user, subscribable: wiki_page_meta, subscribed: true)
      end

      include_examples 'sets the subscription to the wiki pages notifications', false
    end
  end
end
