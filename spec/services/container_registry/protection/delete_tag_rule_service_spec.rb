# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::DeleteTagRuleService, '#execute', feature_category: :container_registry do
  include ContainerRegistryHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let_it_be_with_refind(:container_protection_tag_rule) do
    create(:container_registry_protection_tag_rule, project: project)
  end

  subject(:service_execute) do
    described_class.new(container_protection_tag_rule, current_user: current_user).execute
  end

  before do
    stub_gitlab_api_client_to_support_gitlab_api(supported: true)
  end

  shared_examples 'a successful service response' do
    it_behaves_like 'returning a success service response' do
      it 'contains the correct payload with no errors' do
        is_expected.to have_attributes(
          errors: be_blank,
          message: be_blank,
          payload: { container_protection_tag_rule: container_protection_tag_rule }
        )
      end
    end

    it 'raises a RecordNotFound error' do
      service_execute

      expect { container_protection_tag_rule.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  shared_examples 'an erroneous service response' do |message: nil|
    it_behaves_like 'returning an error service response', message: message do
      it 'contains the message and an empty rule' do
        is_expected.to have_attributes(message: be_present, payload: { container_protection_tag_rule: be_blank })
      end
    end

    it 'does not delete the protection rule' do
      expect { service_execute }.not_to change { ContainerRegistry::Protection::TagRule.count }

      expect { container_protection_tag_rule.reload }.not_to raise_error
    end
  end

  it_behaves_like 'a successful service response'

  it 'deletes the container registry protection rule in the database' do
    expect { service_execute }
      .to change {
            project.reload.container_registry_protection_tag_rules
          }.from([container_protection_tag_rule]).to([])
      .and change { ::ContainerRegistry::Protection::TagRule.count }.from(1).to(0)
  end

  context 'with deleted container registry protection rule' do
    let!(:container_protection_tag_rule) do
      create(:container_registry_protection_tag_rule, project: project, tag_name_pattern: 'v1*').destroy!
    end

    it_behaves_like 'a successful service response'
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
        message: 'Unauthorized to delete a protection rule for container image tags'
    end
  end

  context 'without container registry protection rule' do
    let(:container_protection_tag_rule) { nil }

    it { expect { service_execute }.to raise_error(ArgumentError) }
  end

  context 'without current_user' do
    let(:current_user) { nil }
    let(:container_protection_tag_rule) { build_stubbed(:container_registry_protection_tag_rule, project: project) }

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
