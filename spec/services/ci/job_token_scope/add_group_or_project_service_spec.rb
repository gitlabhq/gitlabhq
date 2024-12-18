# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobTokenScope::AddGroupOrProjectService, feature_category: :continuous_integration do
  let_it_be(:source_project) { create(:project) }
  let_it_be(:target_project) { create(:project) }
  let_it_be(:target_group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:policies) { %w[read_containers read_packages] }

  let(:response_success) { ServiceResponse.success }

  subject(:service_execute) do
    described_class.new(source_project, current_user).execute(target, default_permissions: false, policies: policies)
  end

  describe '#execute' do
    context 'when group is a target to add' do
      let(:target) { target_group }
      let(:add_group_service_double) { instance_double(::Ci::JobTokenScope::AddGroupService) }

      before do
        allow(::Ci::JobTokenScope::AddGroupService).to receive(:new)
        .with(source_project, current_user)
        .and_return(add_group_service_double)
      end

      it 'calls AddGroupService to add a target' do
        expect(add_group_service_double)
          .to receive(:execute).with(target, default_permissions: false, policies: policies)
          .and_return(response_success)

        expect(service_execute).to eq(response_success)
      end
    end

    context 'when project is a target to add' do
      let(:target) { target_project }
      let(:add_project_service_double) { instance_double(::Ci::JobTokenScope::AddProjectService) }
      let(:policies) { %w[read_containers] }

      before do
        allow(::Ci::JobTokenScope::AddProjectService).to receive(:new)
        .with(source_project, current_user)
        .and_return(add_project_service_double)
      end

      it 'calls AddProjectService to add a target' do
        expect(add_project_service_double)
          .to receive(:execute).with(target, default_permissions: false, policies: policies)
          .and_return(response_success)

        expect(service_execute).to eq(response_success)
      end
    end

    context 'when not found object is a target to add' do
      let(:target) { nil }
      let(:expected_error_message) do
        Ci::JobTokenScope::EditScopeValidations::TARGET_DOES_NOT_EXIST
      end

      it 'returns a response error' do
        response = service_execute

        expect(response).to be_kind_of(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq(expected_error_message)
        expect(response.reason).to eq(:not_found)
      end
    end
  end
end
