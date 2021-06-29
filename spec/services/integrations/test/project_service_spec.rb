# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Test::ProjectService do
  include AfterNextHelpers

  describe '#execute' do
    let_it_be(:project) { create(:project) }

    let(:integration) { create(:integrations_slack, project: project) }
    let(:user) { project.owner }
    let(:event) { nil }
    let(:sample_data) { { data: 'sample' } }
    let(:success_result) { { success: true, result: {} } }

    subject { described_class.new(integration, user, event).execute }

    context 'without event specified' do
      it 'tests the integration with default data' do
        allow(Gitlab::DataBuilder::Push).to receive(:build_sample).and_return(sample_data)

        expect(integration).to receive(:test).with(sample_data).and_return(success_result)
        expect(subject).to eq(success_result)
      end

      context 'with Integrations::PipelinesEmail' do
        let(:integration) { create(:pipelines_email_integration, project: project) }

        it_behaves_like 'tests for integration with pipeline data'
      end
    end

    context 'with event specified' do
      context 'event not supported by integration' do
        let(:integration) { create(:jira_integration, project: project) }
        let(:event) { 'push' }

        it 'returns error message' do
          expect(subject).to include({ status: :error, message: 'Testing not available for this event' })
        end
      end

      context 'push' do
        let(:event) { 'push' }

        it 'executes integration' do
          allow(Gitlab::DataBuilder::Push).to receive(:build_sample).and_return(sample_data)

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end
      end

      context 'tag_push' do
        let(:event) { 'tag_push' }

        it 'executes integration' do
          allow(Gitlab::DataBuilder::Push).to receive(:build_sample).and_return(sample_data)

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end
      end

      context 'note' do
        let(:event) { 'note' }

        it 'returns error message if not enough data' do
          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the project has notes.' })
        end

        it 'executes integration' do
          create(:note, project: project)

          allow(Gitlab::DataBuilder::Note).to receive(:build).and_return(sample_data)
          allow_next(NotesFinder).to receive(:execute).and_return(Note.all)

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end
      end

      shared_examples_for 'a test of an integration that operates on issues' do
        let(:issue) { build(:issue) }

        it 'returns error message if not enough data' do
          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the project has issues.' })
        end

        it 'executes integration' do
          allow(project).to receive(:issues).and_return([issue])
          allow(issue).to receive(:to_hook_data).and_return(sample_data)
          allow_next(IssuesFinder).to receive(:execute).and_return([issue])

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end
      end

      context 'issue' do
        let(:event) { 'issue' }

        it_behaves_like 'a test of an integration that operates on issues'
      end

      context 'confidential_issue' do
        let(:event) { 'confidential_issue' }

        it_behaves_like 'a test of an integration that operates on issues'
      end

      context 'merge_request' do
        let(:event) { 'merge_request' }
        let(:merge_request) { build(:merge_request) }

        it 'returns error message if not enough data' do
          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the project has merge requests.' })
        end

        it 'executes integration' do
          allow(merge_request).to receive(:to_hook_data).and_return(sample_data)
          allow_next(MergeRequestsFinder).to receive(:execute).and_return([merge_request])

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to include(success_result)
        end
      end

      context 'deployment' do
        let_it_be(:project) { create(:project, :test_repo) }

        let(:deployment) { build(:deployment) }
        let(:event) { 'deployment' }

        it 'returns error message if not enough data' do
          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the project has deployments.' })
        end

        it 'executes integration' do
          allow(Gitlab::DataBuilder::Deployment).to receive(:build).and_return(sample_data)
          allow_next(DeploymentsFinder).to receive(:execute).and_return([deployment])

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end
      end

      context 'pipeline' do
        let(:event) { 'pipeline' }
        let(:pipeline) { build(:ci_pipeline) }

        it 'returns error message if not enough data' do
          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the project has CI pipelines.' })
        end

        it 'executes integration' do
          allow(Gitlab::DataBuilder::Pipeline).to receive(:build).and_return(sample_data)
          allow_next(Ci::PipelinesFinder).to receive(:execute).and_return([pipeline])

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end
      end

      context 'wiki_page' do
        let_it_be(:project) { create(:project, :wiki_repo) }

        let(:event) { 'wiki_page' }

        it 'returns error message if wiki disabled' do
          allow(project).to receive(:wiki_enabled?).and_return(false)

          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the wiki is enabled and has pages.' })
        end

        it 'returns error message if not enough data' do
          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the wiki is enabled and has pages.' })
        end

        it 'executes integration' do
          create(:wiki_page, wiki: project.wiki)
          allow(Gitlab::DataBuilder::WikiPage).to receive(:build).and_return(sample_data)

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end
      end
    end
  end
end
