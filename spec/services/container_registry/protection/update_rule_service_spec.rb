# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::UpdateRuleService, '#execute', feature_category: :container_registry do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let_it_be_with_reload(:container_registry_protection_rule) do
    create(:container_registry_protection_rule, project: project)
  end

  let(:service) { described_class.new(container_registry_protection_rule, current_user: current_user, params: params) }

  let(:params) do
    attributes_for(
      :container_registry_protection_rule,
      repository_path_pattern: "#{container_registry_protection_rule.repository_path_pattern}-updated",
      minimum_access_level_for_delete: 'owner',
      minimum_access_level_for_push: 'owner'
    )
  end

  subject(:service_execute) { service.execute }

  shared_examples 'a successful service response with side effect' do
    let(:expected_attributes) { params }

    it_behaves_like 'returning a success service response' do
      it do
        is_expected.to have_attributes(
          errors: be_blank,
          payload: {
            container_registry_protection_rule:
            be_a(ContainerRegistry::Protection::Rule)
            .and(have_attributes(expected_attributes))
          }
        )
      end
    end

    it { expect { subject }.not_to change { ContainerRegistry::Protection::Rule.count } }

    it { subject.tap { expect(container_registry_protection_rule.reload).to have_attributes expected_attributes } }
  end

  shared_examples 'an erroneous service response with side effect' do |message: nil|
    it_behaves_like 'returning an error service response', message: message do
      it do
        is_expected.to have_attributes(
          errors: be_present,
          payload: { container_registry_protection_rule: nil }
        )
      end
    end

    it { expect { subject }.not_to change { ContainerRegistry::Protection::Rule.count } }
    it { expect { subject }.not_to change { container_registry_protection_rule.reload.updated_at } }
  end

  it_behaves_like 'a successful service response with side effect'

  context 'with disallowed params' do
    let(:params) { super().merge!(project_id: 1, unsupported_param: 'unsupported_param_value') }

    it_behaves_like 'a successful service response with side effect' do
      let(:expected_attributes) { params.except(:project_id, :unsupported_param) }
    end
  end

  context 'with invalid params' do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength, Layout/ArrayAlignment -- Avoid formatting to keep one-line table syntax
    where(:params_invalid, :message_expected) do
      { repository_path_pattern: '' }                                                    | ["Repository path pattern can't be blank",
                                                                                            "Repository path pattern should be a valid container repository path with optional wildcard characters.",
                                                                                            "Repository path pattern should start with the project's full path"]
      { repository_path_pattern: 'wrong-project-scope/repository-path' }                 | ["Repository path pattern should start with the project's full path"]
      lazy { { repository_path_pattern: "#{project.full_path}/path-invalid-chars-#@" } } | ["Repository path pattern should be a valid container repository path with optional wildcard characters."]
      { minimum_access_level_for_delete: 1000 }                                          | "'1000' is not a valid minimum_access_level_for_delete"
      { minimum_access_level_for_push: 1000 }                                            | "'1000' is not a valid minimum_access_level_for_push"
    end
    # rubocop:enable Layout/LineLength, Layout/ArrayAlignment

    with_them do
      let(:params) do
        super().merge(params_invalid)
      end

      it_behaves_like 'an erroneous service response with side effect', message: params[:message_expected]

      it { is_expected.to have_attributes message: message_expected }
    end
  end

  context 'with empty params' do
    let(:params) { {} }

    it_behaves_like 'a successful service response with side effect' do
      let(:expected_attributes) { container_registry_protection_rule.attributes }
    end

    it { expect { service_execute }.not_to change { container_registry_protection_rule.reload.updated_at } }
  end

  context 'with nil params' do
    let(:params) { nil }

    it_behaves_like 'a successful service response with side effect' do
      let(:expected_attributes) { container_registry_protection_rule.attributes }
    end

    it { expect { service_execute }.not_to change { container_registry_protection_rule.reload.updated_at } }
  end

  context 'when updated field `repository_path_pattern` is already taken' do
    let_it_be_with_reload(:other_existing_container_registry_protection_rule) do
      create(:container_registry_protection_rule, project: project,
        repository_path_pattern: "#{container_registry_protection_rule.repository_path_pattern}-other")
    end

    let(:params) do
      { repository_path_pattern: other_existing_container_registry_protection_rule.repository_path_pattern }
    end

    it_behaves_like 'an erroneous service response with side effect',
      message: ['Repository path pattern has already been taken']

    it do
      expect { service_execute }.not_to(
        change { other_existing_container_registry_protection_rule.reload.repository_path_pattern }
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
      it_behaves_like 'an erroneous service response with side effect',
        message: 'Unauthorized to update a container registry protection rule'
    end
  end

  context 'without container registry protection rule' do
    let(:container_registry_protection_rule) { nil }
    let(:params) { {} }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end

  context 'without current_user' do
    let(:current_user) { nil }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end
end
