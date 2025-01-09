# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the container registry tag protection rule', :aggregate_failures, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:container_protection_tag_rule) do
    create(:container_registry_protection_tag_rule, project: project)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:container_protection_tag_rule_attributes) do
    build_stubbed(:container_protection_tag_rule, project: project)
  end

  let(:mutation) do
    graphql_mutation(:update_container_protection_tag_rule, input,
      <<~QUERY
      containerProtectionTagRule {
        tagNamePattern
        minimumAccessLevelForDelete
        minimumAccessLevelForPush
      }
      clientMutationId
      errors
      QUERY
    )
  end

  let(:input) do
    {
      id: container_protection_tag_rule.to_global_id,
      tag_name_pattern: 'v2*',
      minimum_access_level_for_delete: 'OWNER',
      minimum_access_level_for_push: 'MAINTAINER'
    }
  end

  let(:mutation_response) { graphql_mutation_response(:update_container_protection_tag_rule) }

  subject(:post_graphql_mutation_update_rule) do
    post_graphql_mutation(mutation, current_user: current_user)
  end

  shared_examples 'a successful response' do
    it 'returns the updated container registry tag protection rule' do
      post_graphql_mutation_update_rule

      expect(mutation_response).to include(
        'errors' => be_blank,
        'containerProtectionTagRule' => {
          'tagNamePattern' => input[:tag_name_pattern],
          'minimumAccessLevelForDelete' => input[:minimum_access_level_for_delete],
          'minimumAccessLevelForPush' => input[:minimum_access_level_for_push]
        }
      )
    end

    it 'updates the rule with the right attributes' do
      post_graphql_mutation_update_rule
      expect(container_protection_tag_rule.reload).to have_attributes(
        tag_name_pattern: input[:tag_name_pattern],
        minimum_access_level_for_push: input[:minimum_access_level_for_push].downcase
      )
    end
  end

  shared_examples 'not updating the tag rule' do
    it 'does not update the tag rule' do
      expect { post_graphql_mutation_update_rule }
        .not_to(change { container_protection_tag_rule.reload.updated_at })
    end
  end

  it_behaves_like 'a successful response'

  context 'with other existing container registry protection rule with same tag_name_pattern' do
    let_it_be_with_reload(:other_existing_container_protection_tag_rule) do
      create(:container_registry_protection_tag_rule, project: project,
        tag_name_pattern: "#{container_protection_tag_rule.tag_name_pattern}-other")
    end

    let(:input) do
      super().merge(tag_name_pattern: other_existing_container_protection_tag_rule.tag_name_pattern)
    end

    it_behaves_like 'not updating the tag rule'

    it 'does not raise any graphql errors' do
      post_graphql_mutation_update_rule

      expect_graphql_errors_to_be_empty
    end

    it 'returns a blank container registry tag protection rule' do
      post_graphql_mutation_update_rule

      expect(mutation_response['containerProtectionTagRule']).to be_blank
    end

    it 'includes error message in response' do
      post_graphql_mutation_update_rule

      expect(mutation_response['errors']).to eq ['Tag name pattern has already been taken']
    end
  end

  context 'with invalid input param `minimumAccessLevelForPush`' do
    let(:input) { super().merge(minimum_access_level_for_push: 'INVALID_ACCESS_LEVEL') }

    it_behaves_like 'not updating the tag rule'

    it 'raises an invalid value error' do
      post_graphql_mutation_update_rule

      expect_graphql_errors_to_include(/invalid value for minimumAccessLevelForPush/)
    end
  end

  context 'with invalid input param `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_delete: 'INVALID_ACCESS_LEVEL') }

    it_behaves_like 'not updating the tag rule'

    it 'raises an invalid value error' do
      post_graphql_mutation_update_rule

      expect_graphql_errors_to_include(/invalid value for minimumAccessLevelForDelete/)
    end
  end

  context 'with invalid input param `tagNamePattern`' do
    let(:input) { super().merge(tag_name_pattern: '') }

    it_behaves_like 'not updating the tag rule'

    it 'returns error with correct error message' do
      post_graphql_mutation_update_rule

      expect_graphql_errors_to_include(/tagNamePattern can't be blank/)
    end
  end

  context 'with blank input fields `minimumAccessLevelForPush` and `minimumAccessLevelForDelete`' do
    let(:input) { super().merge(minimum_access_level_for_push: nil, minimum_access_level_for_delete: nil) }

    it_behaves_like 'not updating the tag rule'

    it 'returns error with correct error message' do
      post_graphql_mutation_update_rule

      expect(mutation_response['errors']).to match_array ["Minimum access level for delete can't be blank",
        "Minimum access level for push can't be blank"]
    end
  end

  context 'when current_user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:current_user) do
      [ref(:developer), ref(:reporter), ref(:guest), ref(:anonymous)]
    end

    with_them do
      it_behaves_like 'not updating the tag rule'

      it 'raises permission errors' do
        post_graphql_mutation_update_rule
        expect_graphql_errors_to_include(/you don't have permission to perform this action/)
      end
    end
  end

  context "when feature flag ':container_registry_protected_tags' disabled" do
    before do
      stub_feature_flags(container_registry_protected_tags: false)
    end

    it_behaves_like 'not updating the tag rule'

    it { post_graphql_mutation_update_rule.tap { expect(mutation_response).to be_blank } }

    it 'returns error of disabled feature flag' do
      post_graphql_mutation_update_rule

      expect_graphql_errors_to_include(/'container_registry_protected_tags' feature flag is disabled/)
    end
  end
end
