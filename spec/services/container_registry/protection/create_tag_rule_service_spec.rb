# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::CreateTagRuleService, '#execute', feature_category: :container_registry do
  include ContainerRegistryHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }

  let(:service) { described_class.new(project: project, current_user: current_user, params: params) }
  let(:params) { attributes_for(:container_registry_protection_tag_rule, project: project) }

  subject(:service_execute) { service.execute }

  before do
    stub_gitlab_api_client_to_support_gitlab_api(supported: true)
  end

  shared_examples 'a successful service response' do
    it_behaves_like 'returning a success service response' do
      it { is_expected.to have_attributes(errors: be_blank) }

      it 'returns the created rule with the correct attributes' do
        is_expected.to have_attributes(
          payload: {
            container_protection_tag_rule:
            be_a(ContainerRegistry::Protection::TagRule)
            .and(have_attributes(
              tag_name_pattern: params[:tag_name_pattern],
              minimum_access_level_for_push: params[:minimum_access_level_for_push].to_s,
              minimum_access_level_for_delete: params[:minimum_access_level_for_delete].to_s
            ))
          }
        )
      end
    end

    it 'creates a new container registry tag protection rule in the database' do
      expect { subject }.to change { ContainerRegistry::Protection::TagRule.count }.by(1)

      expect(
        ContainerRegistry::Protection::TagRule.where(
          project: project,
          tag_name_pattern: params[:tag_name_pattern],
          minimum_access_level_for_push: params[:minimum_access_level_for_push]
        )
      ).to exist
    end
  end

  shared_examples 'an erroneous service response' do |message: nil|
    it_behaves_like 'returning an error service response', message: message do
      it 'returns an error with the correct attributes' do
        is_expected.to have_attributes(errors: be_present, payload: include(container_protection_tag_rule: nil))
      end
    end

    it 'does not create a new container registry tag protection rule in the database' do
      expect { subject }.not_to change { ContainerRegistry::Protection::TagRule.count }
    end

    it 'does not create a container registry tag protection rule with the given params' do
      subject

      expect(
        ContainerRegistry::Protection::TagRule.where(
          project: project,
          tag_name_pattern: params[:tag_name_pattern],
          minimum_access_level_for_push: params[:minimum_access_level_for_push]
        )
      ).not_to exist
    end
  end

  it_behaves_like 'a successful service response'

  context 'with invalid params' do
    using RSpec::Parameterized::TableSyntax

    where(:params_invalid, :message_expected) do
      { tag_name_pattern: '' }      | ["Tag name pattern can't be blank"]
      { tag_name_pattern: '*' }     | ["Tag name pattern not valid RE2 syntax: no argument for repetition operator: *"]
      { minimum_access_level_for_delete: nil }  | ['Access levels should either both be present or both be nil']
      { minimum_access_level_for_push: nil }    | ['Access levels should either both be present or both be nil']
      { minimum_access_level_for_delete: 1000 } | "'1000' is not a valid minimum_access_level_for_delete"
      { minimum_access_level_for_push: 1000 }   | "'1000' is not a valid minimum_access_level_for_push"
    end

    with_them do
      let(:params) { super().merge(params_invalid) }

      it_behaves_like 'an erroneous service response', message: params[:message_expected]

      it { is_expected.to have_attributes message: message_expected }
    end
  end

  context 'with existing container registry protection rule in the database' do
    let_it_be_with_reload(:existing_container_registry_protection_tag_rule) do
      create(:container_registry_protection_tag_rule, project: project)
    end

    context 'when field `tag_name_pattern` is taken' do
      let(:params) do
        super().merge(
          tag_name_pattern: existing_container_registry_protection_tag_rule.tag_name_pattern,
          minimum_access_level_for_push: :owner
        )
      end

      it_behaves_like 'an erroneous service response',
        message: ['Tag name pattern has already been taken'] do
        it { expect { service_execute }.not_to change { existing_container_registry_protection_tag_rule.updated_at } }
      end
    end
  end

  context 'with disallowed params' do
    let(:params) { super().merge(project_id: 1, unsupported_param: 'unsupported_param_value') }

    it_behaves_like 'a successful service response'
  end

  context 'with forbidden user access level (project developer role)' do
    # Because of the access level hierarchy, we can assume that
    # other access levels below developer role will also not be able to
    # create container registry protection rules.
    let_it_be(:current_user) { create(:user, developer_of: project) }

    it_behaves_like 'an erroneous service response',
      message: 'Unauthorized to create a protection rule for container image tags'
  end

  context 'when the maximum number of tag rules already exist in the project' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:current_user) { create(:user, maintainer_of: project) }

    before do
      ContainerRegistry::Protection::TagRule::MAX_TAG_RULES_PER_PROJECT.times do |i|
        create(:container_registry_protection_tag_rule, project: project, tag_name_pattern: "#{i}*")
      end
    end

    it_behaves_like 'an erroneous service response',
      message: 'Maximum number of protection rules have been reached.'
  end

  context 'when the GitLab API is not supported' do
    before do
      stub_gitlab_api_client_to_support_gitlab_api(supported: false)
    end

    it_behaves_like 'an erroneous service response',
      message: 'GitLab container registry API not supported'
  end
end
