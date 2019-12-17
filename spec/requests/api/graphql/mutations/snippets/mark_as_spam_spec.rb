# frozen_string_literal: true

require 'spec_helper'

describe 'Mark snippet as spam' do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:snippet) { create(:personal_snippet) }
  let_it_be(:user_agent_detail) { create(:user_agent_detail, subject: snippet) }
  let(:current_user) { snippet.author }
  let(:mutation) do
    variables = {
      id: snippet.to_global_id.to_s
    }

    graphql_mutation(:mark_as_spam_snippet, variables)
  end

  def mutation_response
    graphql_mutation_response(:mark_as_spam_snippet)
  end

  shared_examples 'does not mark the snippet as spam' do
    it do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { snippet.reload.user_agent_detail.submitted }
    end
  end

  context 'when the user does not have permission' do
    let(:current_user) { other_user }

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

    it_behaves_like 'does not mark the snippet as spam'
  end

  context 'when the user has permission' do
    context 'when user can not mark snippet as spam' do
      it_behaves_like 'does not mark the snippet as spam'
    end

    context 'when user can mark snippet as spam' do
      let(:current_user) { admin }

      before do
        stub_application_setting(akismet_enabled: true)
      end

      it 'marks snippet as spam' do
        expect_next_instance_of(SpamService) do |instance|
          expect(instance).to receive(:mark_as_spam!)
        end

        post_graphql_mutation(mutation, current_user: current_user)
      end
    end
  end
end
