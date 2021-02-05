# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Test::ProjectService do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let(:integration) { create(:slack_service, project: project) }
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

      context 'PipelinesEmailService' do
        let(:integration) { create(:pipelines_email_service, project: project) }

        it_behaves_like 'tests for integration with pipeline data'
      end
    end

    context 'with event specified' do
      context 'event not supported by integration' do
        let(:integration) { create(:jira_service, project: project) }
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
          allow_next_instance_of(NotesFinder) do |finder|
            allow(finder).to receive(:execute).and_return(Note.all)
          end

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end

        context 'when the query optimization feature flag is disabled' do
          before do
            stub_feature_flags(integrations_test_webhook_optimizations: false)
          end

          it 'executes the old query' do
            allow(Gitlab::DataBuilder::Note).to receive(:build).and_return(sample_data)

            expect(NotesFinder).not_to receive(:new)
            expect(project).to receive(:notes).and_return([Note.new])
            expect(integration).to receive(:test).with(sample_data).and_return(success_result)
            expect(subject).to eq(success_result)
          end
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
          allow_next_instance_of(IssuesFinder) do |finder|
            allow(finder).to receive(:execute).and_return([issue])
          end

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end

        context 'when the query optimization feature flag is disabled' do
          before do
            stub_feature_flags(integrations_test_webhook_optimizations: false)
          end

          it 'executes the old query' do
            allow(issue).to receive(:to_hook_data).and_return(sample_data)

            expect(IssuesFinder).not_to receive(:new)
            expect(project).to receive(:issues).and_return([issue])
            expect(integration).to receive(:test).with(sample_data).and_return(success_result)
            expect(subject).to eq(success_result)
          end
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
          allow_next_instance_of(MergeRequestsFinder) do |finder|
            allow(finder).to receive(:execute).and_return([merge_request])
          end

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to include(success_result)
        end

        context 'when the query optimization feature flag is disabled' do
          before do
            stub_feature_flags(integrations_test_webhook_optimizations: false)
          end

          it 'executes the old query' do
            expect(MergeRequestsFinder).not_to receive(:new)
            expect(project).to receive(:merge_requests).and_return([merge_request])

            allow(merge_request).to receive(:to_hook_data).and_return(sample_data)

            expect(integration).to receive(:test).with(sample_data).and_return(success_result)
            expect(subject).to eq(success_result)
          end
        end
      end

      context 'deployment' do
        let_it_be(:project) { create(:project, :test_repo) }
        let(:event) { 'deployment' }

        it 'returns error message if not enough data' do
          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the project has deployments.' })
        end

        it 'executes integration' do
          create(:deployment, project: project)
          allow(Gitlab::DataBuilder::Deployment).to receive(:build).and_return(sample_data)

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(subject).to eq(success_result)
        end
      end

      context 'pipeline' do
        let(:event) { 'pipeline' }

        it 'returns error message if not enough data' do
          expect(integration).not_to receive(:test)
          expect(subject).to include({ status: :error, message: 'Ensure the project has CI pipelines.' })
        end

        it 'executes integration' do
          create(:ci_empty_pipeline, project: project)
          allow(Gitlab::DataBuilder::Pipeline).to receive(:build).and_return(sample_data)

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
