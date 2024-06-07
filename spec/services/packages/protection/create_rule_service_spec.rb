# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Protection::CreateRuleService, '#execute', feature_category: :package_registry do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }

  let(:service) { described_class.new(project: project, current_user: current_user, params: params) }
  let(:current_user) { maintainer }
  let(:params) { attributes_for(:package_protection_rule) }

  subject(:service_execute) { service.execute }

  shared_examples 'a successful service response with side effect' do
    let(:package_protection_rule_count_expected) { 1 }

    it_behaves_like 'returning a success service response' do
      it { is_expected.to have_attributes(payload: { package_protection_rule: be_a(Packages::Protection::Rule) }) }
    end

    it do
      expect { subject }.to change { Packages::Protection::Rule.count }.by(1)

      expect(Packages::Protection::Rule.where(project: project).count).to eq package_protection_rule_count_expected
      expect(Packages::Protection::Rule.where(project: project,
        package_name_pattern: params[:package_name_pattern])).to exist
    end
  end

  shared_examples 'an erroneous service response with side effect' do |message: nil|
    let(:package_protection_rule_count_expected) { 0 }

    it_behaves_like 'returning an error service response', message: message do
      it { is_expected.to have_attributes(payload: include(package_protection_rule: nil)) }
    end

    it do
      expect { subject }.to change { Packages::Protection::Rule.count }.by(0)

      expect(Packages::Protection::Rule.where(project: project).count).to eq package_protection_rule_count_expected
      expect(Packages::Protection::Rule.where(project: project,
        package_name_pattern: params[:package_name_pattern])).not_to exist
    end
  end

  context 'without existing PackageProtectionRules' do
    context 'when fields are valid' do
      it_behaves_like 'a successful service response with side effect'
    end

    context 'when fields are invalid' do
      let(:params) do
        {
          package_name_pattern: '',
          package_type: 'unknown_package_type',
          minimum_access_level_for_push: 1000
        }
      end

      it_behaves_like 'an erroneous service response with side effect',
        message: "'unknown_package_type' is not a valid package_type"
    end
  end

  context 'with existing PackageProtectionRule' do
    let_it_be(:existing_package_protection_rule) { create(:package_protection_rule, project: project) }

    context 'when package name pattern is slightly different' do
      let(:params) do
        attributes_for(
          :package_protection_rule,
          # The field `package_name_pattern` is unique; this is why we change the value in a minimum way
          package_name_pattern: "#{existing_package_protection_rule.package_name_pattern}-unique",
          package_type: existing_package_protection_rule.package_type,
          minimum_access_level_for_push: existing_package_protection_rule.minimum_access_level_for_push
        )
      end

      it_behaves_like 'a successful service response with side effect' do
        let(:package_protection_rule_count_expected) { 2 }
      end
    end

    context 'when field `package_name_pattern` is taken' do
      let(:params) do
        attributes_for(
          :package_protection_rule,
          package_name_pattern: existing_package_protection_rule.package_name_pattern,
          package_type: existing_package_protection_rule.package_type,
          minimum_access_level_for_push: existing_package_protection_rule.minimum_access_level_for_push
        )
      end

      it { is_expected.to be_error }

      it do
        expect { service_execute }.to change { Packages::Protection::Rule.count }.by(0)

        expect(Packages::Protection::Rule.where(project: project).count).to eq 1
        expect(
          Packages::Protection::Rule.where(
            project: project,
            package_name_pattern: params[:package_name_pattern]
          )
        ).to exist
      end
    end
  end

  context 'when disallowed params are passed' do
    let(:params) do
      attributes_for(:package_protection_rule)
        .merge(
          project_id: 1,
          unsupported_param: 'unsupported_param_value'
        )
    end

    it_behaves_like 'a successful service response with side effect'
  end

  context 'with forbidden user access level (project developer role)' do
    # Because of the access level hierarchy, we can assume that
    # other access levels below developer role will also not be able to
    # create package protection rules.
    let_it_be(:developer) { create(:user, developer_of: project) }

    let(:current_user) { developer }

    it_behaves_like 'an erroneous service response with side effect',
      message: 'Unauthorized to create a package protection rule'
  end
end
