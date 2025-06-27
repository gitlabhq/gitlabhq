# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::UpdateTagRuleService, '#execute', feature_category: :container_registry do
  include ContainerRegistryHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let_it_be_with_reload(:container_protection_tag_rule) do
    create(:container_registry_protection_tag_rule, project: project)
  end

  let(:service) { described_class.new(container_protection_tag_rule, current_user: current_user, params: params) }

  let(:params) do
    attributes_for(
      :container_registry_protection_tag_rule,
      tag_name_pattern: 'v1*',
      minimum_access_level_for_delete: 'owner',
      minimum_access_level_for_push: 'owner'
    )
  end

  subject(:service_execute) { service.execute }

  before do
    stub_gitlab_api_client_to_support_gitlab_api(supported: true)
  end

  shared_examples 'a successful service response' do
    let(:expected_attributes) { params }

    it_behaves_like 'returning a success service response' do
      it 'returns the update rule with no errors' do
        is_expected.to have_attributes(
          errors: be_blank,
          payload: {
            container_protection_tag_rule:
            be_a(ContainerRegistry::Protection::TagRule)
            .and(have_attributes(expected_attributes))
          }
        )
      end
    end

    it { expect { subject }.not_to change { ContainerRegistry::Protection::TagRule.count } }

    it { subject.tap { expect(container_protection_tag_rule.reload).to have_attributes expected_attributes } }
  end

  shared_examples 'an erroneous service response' do |message: nil|
    it_behaves_like 'returning an error service response', message: message do
      it 'returns a blank rule with errors' do
        is_expected.to have_attributes(
          errors: be_present,
          payload: { container_protection_tag_rule: nil }
        )
      end
    end

    it { expect { subject }.not_to change { ContainerRegistry::Protection::TagRule.count } }
    it { expect { subject }.not_to change { container_protection_tag_rule.reload.updated_at } }
  end

  it_behaves_like 'a successful service response'

  context 'with disallowed params' do
    let(:params) { super().merge!(project_id: 1, unsupported_param: 'unsupported_param_value') }

    it_behaves_like 'a successful service response' do
      let(:expected_attributes) { params.except(:project_id, :unsupported_param) }
    end
  end

  context 'with invalid params' do
    using RSpec::Parameterized::TableSyntax

    where(:params_invalid, :message_expected) do
      { tag_name_pattern: '' }      | ["Tag name pattern can't be blank"]
      { tag_name_pattern: '*' }     | ['Tag name pattern not valid RE2 syntax: no argument for repetition operator: *']
      { minimum_access_level_for_delete: nil }  | ['Access levels should either both be present or both be nil']
      { minimum_access_level_for_push: nil }    | ['Access levels should either both be present or both be nil']
      { minimum_access_level_for_delete: 1000 } | "'1000' is not a valid minimum_access_level_for_delete"
      { minimum_access_level_for_push: 1000 }   | "'1000' is not a valid minimum_access_level_for_push"
    end

    with_them do
      let(:params) do
        super().merge(params_invalid)
      end

      it_behaves_like 'an erroneous service response', message: params[:message_expected]

      it { is_expected.to have_attributes message: message_expected }
    end
  end

  context 'with empty params' do
    let(:params) { {} }

    it_behaves_like 'a successful service response' do
      let(:expected_attributes) { container_protection_tag_rule.attributes }
    end

    it { expect { service_execute }.not_to change { container_protection_tag_rule.reload.updated_at } }
  end

  context 'with nil params' do
    let(:params) { nil }

    it_behaves_like 'a successful service response' do
      let(:expected_attributes) { container_protection_tag_rule.attributes }
    end

    it { expect { service_execute }.not_to change { container_protection_tag_rule.reload.updated_at } }
  end

  context 'when updated field `tag_name_pattern` is already taken' do
    let_it_be_with_reload(:other_existing_container_protection_tag_rule) do
      create(:container_registry_protection_tag_rule, project: project,
        tag_name_pattern: 'v1*')
    end

    let(:params) do
      { tag_name_pattern: other_existing_container_protection_tag_rule.tag_name_pattern }
    end

    it_behaves_like 'an erroneous service response',
      message: ['Tag name pattern has already been taken']

    it 'does not update the tag name pattern' do
      expect { service_execute }.not_to(
        change { other_existing_container_protection_tag_rule.reload.tag_name_pattern }
      )
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
      it_behaves_like 'an erroneous service response',
        message: 'Unauthorized to update a protection rule for container image tags'
    end
  end

  context 'without container registry tag protection rule' do
    let(:container_protection_tag_rule) { nil }
    let(:params) { {} }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end

  context 'without current_user' do
    let(:current_user) { nil }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end

  context 'when the GitLab API is not supported' do
    before do
      stub_gitlab_api_client_to_support_gitlab_api(supported: false)
    end

    it_behaves_like 'an erroneous service response',
      message: 'GitLab container registry API not supported'
  end
end
