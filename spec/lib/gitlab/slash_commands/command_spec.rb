# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Command, feature_category: :integrations do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:chat_name) { double(:chat_name, user: user) }

  describe '#execute' do
    subject do
      described_class.new(project, chat_name, params).execute
    end

    context 'when no command is available' do
      let(:params) { { text: 'issue show 1' } }
      let(:project) { create(:project, has_external_issue_tracker: true) }

      it 'displays 404 messages' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('404 not found')
      end
    end

    context 'when an unknown command is triggered' do
      let(:params) { { command: '/gitlab', text: "unknown command 123" } }

      it 'displays the help message' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('The specified command is not valid')
        expect(subject[:text]).to include('/gitlab [project name or alias] issue show <id>')
      end
    end

    context 'the user can not create an issue' do
      let(:params) { { text: "issue create my new issue" } }

      it 'rejects the actions' do
        expect(subject[:response_type]).to be(:ephemeral)
        expect(subject[:text]).to start_with('You are not allowed')
      end
    end

    context 'when trying to do deployment' do
      let(:params) { { text: 'deploy staging to production' } }
      let!(:build) { create(:ci_build, pipeline: pipeline) }
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:staging) { create(:environment, name: 'staging', project: project) }
      let!(:deployment) { create(:deployment, :success, environment: staging, deployable: build) }

      let!(:manual) do
        create(:ci_build, :manual, pipeline: pipeline,
          name: 'first',
          environment: 'production')
      end

      context 'and user can not create deployment' do
        it 'returns action' do
          expect(subject[:response_type]).to be(:ephemeral)
          expect(subject[:text]).to start_with('You are not allowed')
        end
      end

      context 'and user has deployment permission' do
        before do
          build.project.add_developer(user)

          create(:protected_branch, :developers_can_merge,
            name: build.ref, project: project)
        end

        it 'returns action' do
          expect(subject[:text]).to include('Deployment started from staging to production')
          expect(subject[:response_type]).to be(:in_channel)
        end

        context 'when duplicate action exists' do
          let!(:manual2) do
            create(:ci_build, :manual, pipeline: pipeline,
              name: 'second',
              environment: 'production')
          end

          it 'returns error' do
            expect(subject[:response_type]).to be(:ephemeral)
            expect(subject[:text]).to include("Couldn't find a deployment manual action.")
          end
        end
      end
    end
  end

  describe '#match_command' do
    subject { described_class.new(project, chat_name, params).match_command.first }

    context 'IssueShow is triggered' do
      let(:params) { { text: 'issue show 123' } }

      it { is_expected.to eq(Gitlab::SlashCommands::IssueShow) }
    end

    context 'IssueCreate is triggered' do
      let(:params) { { text: 'issue create my title' } }

      it { is_expected.to eq(Gitlab::SlashCommands::IssueNew) }
    end

    context 'IssueSearch is triggered' do
      let(:params) { { text: 'issue search my query' } }

      it { is_expected.to eq(Gitlab::SlashCommands::IssueSearch) }
    end

    context 'IssueMove is triggered' do
      let(:params) { { text: 'issue move #78291 to gitlab/gitlab-ci' } }

      it { is_expected.to eq(Gitlab::SlashCommands::IssueMove) }
    end

    context 'IssueComment is triggered' do
      let(:params) { { text: "issue comment #503\ncomment body" } }

      it { is_expected.to eq(Gitlab::SlashCommands::IssueComment) }
    end

    context 'when incident declare is triggered' do
      context 'IncidentNew is triggered' do
        let(:params) { { text: 'incident declare' } }

        it { is_expected.to eq(Gitlab::SlashCommands::IncidentManagement::IncidentNew) }
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(incident_declare_slash_command: false)
        end

        context 'IncidentNew is triggered' do
          let(:params) { { text: 'incident declare' } }

          it { is_expected.not_to eq(Gitlab::SlashCommands::IncidentManagement::IncidentNew) }
        end
      end
    end
  end
end
