# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a container registry tag protection rule', :aggregate_failures, feature_category: :container_registry do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_refind(:container_protection_rule) do
    create(:container_registry_protection_tag_rule, project: project)
  end

  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:mutation) { graphql_mutation(:delete_container_protection_tag_rule, input) }
  let(:mutation_response) { graphql_mutation_response(:delete_container_protection_tag_rule) }
  let(:input) { { id: container_protection_rule.to_global_id } }

  subject(:post_graphql_mutation_delete_container_protection_tag_rule) do
    post_graphql_mutation(mutation, current_user: current_user)
  end

  shared_examples 'an erroneous response' do
    it { post_graphql_mutation_delete_container_protection_tag_rule.tap { expect(mutation_response).to be_blank } }

    it 'does not delete the protection rule' do
      expect { post_graphql_mutation_delete_container_protection_tag_rule }
        .not_to change { ::ContainerRegistry::Protection::TagRule.count }
    end
  end

  shared_examples 'returning a permission error' do
    it 'returns a permission error' do
      post_graphql_mutation_delete_container_protection_tag_rule

      expect_graphql_errors_to_include(/you don't have permission to perform this action/)
    end
  end

  it_behaves_like 'a working GraphQL mutation'

  it 'responds with deleted container registry tag protection rule' do
    expect { post_graphql_mutation_delete_container_protection_tag_rule }
      .to change { ::ContainerRegistry::Protection::TagRule.count }.from(1).to(0)

    expect(mutation_response).to include(
      'errors' => be_blank,
      'containerProtectionTagRule' => {
        'id' => container_protection_rule.to_global_id.to_s,
        'tagNamePattern' => container_protection_rule.tag_name_pattern,
        'minimumAccessLevelForDelete' => container_protection_rule.minimum_access_level_for_delete.upcase,
        'minimumAccessLevelForPush' => container_protection_rule.minimum_access_level_for_push.upcase
      }
    )
  end

  context 'with existing container registry tag protection rule belonging to other project' do
    let_it_be(:container_protection_rule) { create(:container_registry_protection_tag_rule) }

    it_behaves_like 'an erroneous response'
    it_behaves_like 'returning a permission error'
  end

  context 'with deleted container registry tag protection rule' do
    let!(:container_protection_rule) do
      create(:container_registry_protection_tag_rule, project: project, tag_name_pattern: 'v1*').destroy!
    end

    it_behaves_like 'an erroneous response'
    it_behaves_like 'returning a permission error'
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
      it_behaves_like 'an erroneous response'
      it_behaves_like 'returning a permission error'
    end
  end

  context "when feature flag ':container_registry_protected_tags' disabled" do
    before do
      stub_feature_flags(container_registry_protected_tags: false)
    end

    it_behaves_like 'an erroneous response'

    it 'returns an error on the disabled feature flag' do
      post_graphql_mutation_delete_container_protection_tag_rule

      expect_graphql_errors_to_include(/'container_registry_protected_tags' feature flag is disabled/)
    end
  end
end
