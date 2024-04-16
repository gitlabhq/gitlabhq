# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Protection::DeleteRuleService, '#execute', feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let_it_be_with_refind(:package_protection_rule) { create(:package_protection_rule, project: project) }

  subject { described_class.new(package_protection_rule, current_user: current_user).execute }

  shared_examples 'a successful service response' do
    it { is_expected.to be_success }

    it {
      is_expected.to have_attributes(
        errors: be_blank,
        message: be_blank,
        payload: { package_protection_rule: package_protection_rule }
      )
    }

    it { subject.tap { expect { package_protection_rule.reload }.to raise_error ActiveRecord::RecordNotFound } }
  end

  shared_examples 'an erroneous service response' do
    it { is_expected.to be_error }
    it { is_expected.to have_attributes(message: be_present, payload: { package_protection_rule: be_blank }) }

    it do
      expect { subject }.not_to change { Packages::Protection::Rule.count }

      expect { package_protection_rule.reload }.not_to raise_error
    end
  end

  it_behaves_like 'a successful service response'

  it 'deletes the package protection rule in the database' do
    expect { subject }
    .to change { project.reload.package_protection_rules }.from([package_protection_rule]).to([])
    .and change { ::Packages::Protection::Rule.count }.from(1).to(0)
  end

  context 'with deleted package protection rule' do
    let!(:package_protection_rule) do
      create(:package_protection_rule, project: project, package_name_pattern: 'protection_rule_deleted').destroy!
    end

    it_behaves_like 'a successful service response'
  end

  context 'when error occurs during delete operation' do
    before do
      allow(package_protection_rule).to receive(:destroy!).and_raise(StandardError.new('Some error'))
    end

    it_behaves_like 'an erroneous service response'

    it { is_expected.to have_attributes message: /Some error/ }
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

      it { is_expected.to have_attributes message: /Unauthorized to delete a package protection rule/ }
    end
  end

  context 'without package protection rule' do
    let(:package_protection_rule) { nil }

    it { expect { subject }.to raise_error(ArgumentError) }
  end

  context 'without current_user' do
    let(:current_user) { nil }
    let(:package_protection_rule) { build_stubbed(:package_protection_rule, project: project) }

    it { expect { subject }.to raise_error(ArgumentError) }
  end
end
