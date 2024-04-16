# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Protection::UpdateRuleService, '#execute', feature_category: :environment_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let_it_be_with_reload(:package_protection_rule) { create(:package_protection_rule, project: project) }

  let(:service) { described_class.new(package_protection_rule, current_user: current_user, params: params) }

  let(:params) do
    attributes_for(
      :package_protection_rule,
      package_name_pattern: "#{package_protection_rule.package_name_pattern}-updated",
      package_type: 'npm',
      push_protected_up_to_access_level: 'owner'
    )
  end

  subject(:service_execute) { service.execute }

  shared_examples 'a successful service response' do
    let(:expected_attributes) { params }

    it { is_expected.to be_success }

    it do
      is_expected.to have_attributes(
        errors: be_blank,
        message: be_blank,
        payload: { package_protection_rule: be_a(Packages::Protection::Rule).and(have_attributes(expected_attributes)) }
      )
    end

    it { expect { subject }.not_to change { Packages::Protection::Rule.count } }

    it { subject.tap { expect(package_protection_rule.reload).to have_attributes expected_attributes } }
  end

  shared_examples 'an erroneous service response' do
    it { is_expected.to be_error }

    it do
      is_expected.to have_attributes(
        errors: be_present,
        message: be_present,
        payload: { package_protection_rule: nil }
      )
    end

    it { expect { subject }.not_to change { Packages::Protection::Rule.count } }
    it { expect { subject }.not_to change { package_protection_rule.reload.updated_at } }
  end

  it_behaves_like 'a successful service response'

  context 'with disallowed params' do
    let(:params) { super().merge!(project_id: 1, unsupported_param: 'unsupported_param_value') }

    it_behaves_like 'a successful service response' do
      let(:expected_attributes) { params.except(:project_id, :unsupported_param) }
    end
  end

  context 'when fields are invalid' do
    let(:params) do
      { package_name_pattern: '', package_type: 'unknown_package_type',
        push_protected_up_to_access_level: 1000 }
    end

    it_behaves_like 'an erroneous service response'

    it { is_expected.to have_attributes message: /'unknown_package_type' is not a valid package_type/ }
  end

  context 'with empty params' do
    let(:params) { {} }

    it_behaves_like 'a successful service response' do
      let(:expected_attributes) { package_protection_rule.attributes }
    end

    it { expect { service_execute }.not_to change { package_protection_rule.reload.updated_at } }
  end

  context 'with nil params' do
    let(:params) { nil }

    it_behaves_like 'a successful service response' do
      let(:expected_attributes) { package_protection_rule.attributes }
    end

    it { expect { service_execute }.not_to change { package_protection_rule.reload.updated_at } }
  end

  context 'when updated field `package_name_pattern` is already taken' do
    let_it_be_with_reload(:other_existing_package_protection_rule) do
      create(:package_protection_rule, project: project,
        package_name_pattern: "#{package_protection_rule.package_name_pattern}-other")
    end

    let(:params) { { package_name_pattern: other_existing_package_protection_rule.package_name_pattern } }

    it_behaves_like 'an erroneous service response'

    it do
      expect { service_execute }.not_to(
        change { other_existing_package_protection_rule.reload.package_name_pattern }
      )
    end

    it do
      is_expected.to have_attributes(
        errors: match_array([/Package name pattern has already been taken/]),
        message: match_array([/Package name pattern has already been taken/])
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
      it_behaves_like 'an erroneous service response'

      it { is_expected.to have_attributes errors: match_array(/Unauthorized/), message: /Unauthorized/ }
    end
  end

  context 'without package protection rule' do
    let(:package_protection_rule) { nil }
    let(:params) { {} }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end

  context 'without current_user' do
    let(:current_user) { nil }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end
end
