# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::GlobalSlackHandler, feature_category: :integrations do
  include AfterNextHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be_with_reload(:slack_integration) do
    create(:gitlab_slack_application_integration, project: project).slack_integration
  end

  let(:chat_name) { instance_double('ChatName', user: user) }
  let(:verification_token) { '123' }

  before do
    stub_application_setting(slack_app_verification_token: verification_token)
  end

  def handler(params)
    described_class.new(params)
  end

  def handler_with_valid_token(params)
    handler(params.merge(token: verification_token))
  end

  it 'does not serve a request if token is invalid' do
    result = handler(token: '123456', text: 'help').trigger

    expect(result).to be_falsey
  end

  context 'with valid token' do
    context 'with incident declare command' do
      it 'calls command handler with no project alias' do
        expect_next(Gitlab::SlashCommands::Command).to receive(:execute)
        expect_next(ChatNames::FindUserService).to receive(:execute).and_return(chat_name)

        handler_with_valid_token(
          text: "incident declare",
          team_id: slack_integration.team_id
        ).trigger
      end
    end

    it 'calls command handler if project alias is valid' do
      expect_next(Gitlab::SlashCommands::Command).to receive(:execute)
      expect_next(ChatNames::FindUserService).to receive(:execute).and_return(chat_name)

      slack_integration.update!(alias: project.full_path)

      handler_with_valid_token(
        text: "#{project.full_path} issue new title",
        team_id: slack_integration.team_id
      ).trigger
    end

    it 'returns error if project alias not found' do
      expect_next(Gitlab::SlashCommands::Command).not_to receive(:execute)
      expect_next(
        Gitlab::SlashCommands::Presenters::Error,
        'GitLab error: project or alias not found'
      ).to receive(:message)

      handler_with_valid_token(
        text: "fake/fake issue new title",
        team_id: slack_integration.team_id
      ).trigger
    end

    it 'returns authorization request' do
      expect_next(ChatNames::AuthorizeUserService).to receive(:execute)
      expect_next(Gitlab::SlashCommands::Presenters::Access).to receive(:authorize)

      slack_integration.update!(alias: project.full_path)

      handler_with_valid_token(
        text: "#{project.full_path} issue new title",
        team_id: slack_integration.team_id
      ).trigger
    end

    it 'calls help presenter' do
      expect_next(Gitlab::SlashCommands::ApplicationHelp).to receive(:execute)

      handler_with_valid_token(
        text: "help"
      ).trigger
    end

    context 'when integration is group-level' do
      let_it_be(:group) { create(:group) }

      let_it_be_with_reload(:slack_integration) do
        create(:gitlab_slack_application_integration, :group, group: group,
          slack_integration: build(:slack_integration, alias: group.full_path)
        ).slack_integration
      end

      it 'returns error that the project alias not found' do
        expect_next(Gitlab::SlashCommands::Command).not_to receive(:execute)
        expect_next(
          Gitlab::SlashCommands::Presenters::Error,
          'GitLab error: project or alias not found'
        ).to receive(:message)

        handler_with_valid_token(
          text: "#{group.full_path} issue new title",
          team_id: slack_integration.team_id
        ).trigger
      end
    end

    context 'when integration is instance-level' do
      let_it_be_with_reload(:slack_integration) do
        create(:gitlab_slack_application_integration, :instance,
          slack_integration: build(:slack_integration, alias: '_gitlab-instance')
        ).slack_integration
      end

      it 'returns error that the project alias not found' do
        expect_next(Gitlab::SlashCommands::Command).not_to receive(:execute)
        expect_next(
          Gitlab::SlashCommands::Presenters::Error,
          'GitLab error: project or alias not found'
        ).to receive(:message)

        handler_with_valid_token(
          text: "instance issue new title",
          team_id: slack_integration.team_id
        ).trigger
      end
    end
  end
end
