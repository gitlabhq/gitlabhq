# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::AccessRequestService, feature_category: :observability do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:experimental_group) { create(:group) }
  let_it_be(:deployer_project) { create(:project, group: experimental_group, path: 'o11y_aws_deployer') }

  subject(:service) { described_class.new(group, user) }

  before_all do
    automation_bot = Users::Internal.automation_bot
    project.add_developer(automation_bot)
    deployer_project.add_developer(Users::Internal.automation_bot)
  end

  describe '#execute' do
    shared_examples 'returns error with status' do |message, status|
      it "returns #{status} error: #{message}" do
        result = service.execute
        expect(result).to be_error
        expect(result.message).to eq(message)
        expect(result.http_status).to eq(status)
      end
    end

    context 'with invalid parameters' do
      it_behaves_like 'returns error with status', 'Group is required', :bad_request do
        subject(:service) { described_class.new(nil, user) }
      end

      it_behaves_like 'returns error with status', 'User is required', :bad_request do
        subject(:service) { described_class.new(group, nil) }
      end
    end

    context 'when user has developer access' do
      before_all do
        group.add_developer(user)
      end

      context 'with valid parameters' do
        it 'creates a confidential issue with correct content and author' do
          result = service.execute

          expect(result).to be_success

          issue = result[:issue]
          expect(issue).to be_confidential
          expect(issue.title).to eq("Request Observability Access for #{group.name}")
          expect(issue.author).to eq(Users::Internal.automation_bot)
          expect(issue.project.namespace).to eq(group)

          description = issue.description
          expect(description).to include(user.name)
          expect(description).to include("@#{user.username}")
          expect(description).to include(group.name)
          expect(description).to include("Group ID:** #{group.id}")
          expect(description).to include("Member Count:** #{group.members.count}")
        end

        it 'returns existing issue when one already exists and does not create a new one' do
          existing_issue = create(:issue,
            project: project,
            title: "Request Observability Access for #{group.name}",
            author: Users::Internal.automation_bot,
            confidential: true,
            state: 'opened'
          )

          expect(Issues::CreateService).not_to receive(:new)
          result = service.execute

          expect(result).to be_success
          expect(result[:issue]).to eq(existing_issue)
          expect(Issue.count).to eq(1)
        end

        it 'uses automation bot to create the issue' do
          expect(Issues::CreateService).to receive(:new).with(
            container: instance_of(Project),
            current_user: Users::Internal.automation_bot,
            params: hash_including(
              title: "Request Observability Access for #{group.name}",
              confidential: true
            )
          ).and_call_original

          service.execute
        end

        it 'passes authorization when user has developer access and feature flag is enabled' do
          expect(Ability.allowed?(user, :create_observability_access_request, group)).to be true
          expect(::Feature.enabled?(:observability_sass_features, group)).to be true

          result = service.execute
          expect(result).to be_success
        end
      end

      context 'with system dependencies unavailable' do
        it_behaves_like 'returns error with status', 'Project not found', :not_found do
          before do
            allow(Rails.env).to receive(:production?).and_return(false)
            allow(group).to receive_message_chain(:projects, :first).and_return(nil)
          end
        end
      end

      context 'with issue creation failures' do
        it_behaves_like 'returns error with status', 'Issue creation failed', :unprocessable_entity do
          before do
            allow_next_instance_of(Issues::CreateService) do |instance|
              allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Issue creation failed'))
            end
          end
        end

        it 'handles multiple validation errors' do
          allow_next_instance_of(Issues::CreateService) do |instance|
            allow(instance).to receive(:execute)
              .and_return(ServiceResponse.error(message: ['Title required', 'Description too long']))
          end

          result = service.execute
          expect(result).to be_error
          expect(result.message).to eq('Title required, Description too long')
        end
      end
    end

    context 'when user lacks developer access' do
      context 'when feature flag is disabled' do
        it_behaves_like 'returns error with status', 'You are not authorized to request observability access',
          :forbidden do
          before do
            allow(::Feature).to receive(:enabled?).with(:observability_sass_features, group).and_return(false)
          end
        end
      end

      context 'when user lacks required ability' do
        it_behaves_like 'returns error with status', 'You are not authorized to request observability access',
          :forbidden
      end

      context 'when user has insufficient access level' do
        it_behaves_like 'returns error with status', 'You are not authorized to request observability access',
          :forbidden do
          before_all do
            group.add_guest(user)
          end
        end
      end
    end
  end

  describe 'issue content edge cases' do
    before_all do
      group.add_developer(user)
    end

    context 'with special characters and edge data' do
      let(:special_user) { create(:user, name: 'Test "User" & Co.', username: 'test_user_123') }

      subject(:service) { described_class.new(group, special_user) }

      it 'handles special characters and zero counts correctly' do
        group.add_developer(special_user)
        result = service.execute
        description = result[:issue].description

        expect(description).to include('Test "User" & Co.')
        expect(description).to include('@test_user_123')
      end
    end

    it 'includes properly formatted timestamp' do
      freeze_time do
        result = service.execute
        expected_time = Time.current.strftime('%Y-%m-%d %H:%M:%S UTC')
        expect(result[:issue].description).to include("Request Date:** #{expected_time}")
      end
    end
  end

  describe 'project selection' do
    before_all do
      group.add_developer(user)
    end

    shared_examples 'uses correct project container' do
      it 'passes the correct container to Issues::CreateService' do
        expected_container = expected_container_proc.call
        expect(Issues::CreateService).to receive(:new).with(
          container: expected_container,
          current_user: Users::Internal.automation_bot,
          params: anything
        ).and_call_original

        service.execute
      end
    end

    context 'in non-production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it_behaves_like 'uses correct project container' do
        let(:expected_container_proc) { -> { group.projects.first } }
      end
    end

    context 'in production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(Project).to receive(:find_by_id)
          .with(described_class::DEPLOYER_PROJECT_ID)
          .and_return(deployer_project)
      end

      it_behaves_like 'uses correct project container' do
        let(:expected_container_proc) { -> { deployer_project } }
      end
    end
  end
end
