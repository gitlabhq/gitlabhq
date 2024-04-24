# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::DeleteRuleService, '#execute', feature_category: :container_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let_it_be_with_refind(:container_registry_protection_rule) do
    create(:container_registry_protection_rule, project: project)
  end

  subject(:service_execute) do
    described_class.new(container_registry_protection_rule, current_user: current_user).execute
  end

  shared_examples 'a successful service response with side effect' do
    it_behaves_like 'returning a success service response' do
      it do
        is_expected.to have_attributes(
          errors: be_blank,
          message: be_blank,
          payload: { container_registry_protection_rule: container_registry_protection_rule }
        )
      end
    end

    it do
      service_execute

      expect { container_registry_protection_rule.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  shared_examples 'an erroneous service response with side effect'  do |message: nil|
    it_behaves_like 'returning an error service response', message: message do
      it do
        is_expected.to have_attributes(message: be_present, payload: { container_registry_protection_rule: be_blank })
      end
    end

    it do
      expect { service_execute }.not_to change { ContainerRegistry::Protection::Rule.count }

      expect { container_registry_protection_rule.reload }.not_to raise_error
    end
  end

  it_behaves_like 'a successful service response with side effect'

  it 'deletes the container registry protection rule in the database' do
    expect { service_execute }
      .to change {
            project.reload.container_registry_protection_rules
          }.from([container_registry_protection_rule]).to([])
      .and change { ::ContainerRegistry::Protection::Rule.count }.from(1).to(0)
  end

  context 'with deleted container registry protection rule' do
    let!(:container_registry_protection_rule) do
      create(:container_registry_protection_rule, project: project,
        repository_path_pattern: "#{project.full_path}/image-deleted").destroy!
    end

    it_behaves_like 'a successful service response with side effect'
  end

  context 'when error occurs during delete operation' do
    before do
      allow(container_registry_protection_rule).to receive(:destroy!).and_raise(StandardError.new('Some error'))
    end

    it_behaves_like 'an erroneous service response with side effect', message: 'Some error'
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
        message: 'Unauthorized to delete a container registry protection rule'
    end
  end

  context 'without container registry protection rule' do
    let(:container_registry_protection_rule) { nil }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end

  context 'without current_user' do
    let(:current_user) { nil }
    let(:container_registry_protection_rule) { build_stubbed(:container_registry_protection_rule, project: project) }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end
end
