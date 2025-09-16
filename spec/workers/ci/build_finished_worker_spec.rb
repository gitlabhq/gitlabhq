# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildFinishedWorker, feature_category: :continuous_integration do
  include AfterNextHelpers

  subject { described_class.new.perform(build.id) }

  describe '#perform' do
    context 'when build exists' do
      let_it_be(:build) do
        create(:ci_build, :success, user: create(:user), pipeline: create(:ci_pipeline))
      end

      before do
        expect(Ci::Build).to receive(:find_by).with({ id: build.id }).and_return(build)
      end

      it 'calculates coverage and calls hooks', :aggregate_failures do
        expect(build).to receive(:update_coverage).ordered

        expect_next(Ci::BuildReportResultService).to receive(:execute).with(build)

        expect(build).to receive(:execute_hooks)
        expect(ChatNotificationWorker).not_to receive(:perform_async)
        expect(Ci::ArchiveTraceWorker).to receive(:perform_in)

        subject
      end

      context 'when build is failed' do
        before do
          build.update!(status: :failed)
        end

        it 'adds a todo' do
          expect(::Ci::MergeRequests::AddTodoWhenBuildFailsWorker).to receive(:perform_async)

          subject
        end

        context 'when a build can be auto-retried' do
          before do
            allow(build)
              .to receive(:auto_retry_allowed?)
              .and_return(true)
          end

          it 'does not add a todo' do
            expect(::Ci::MergeRequests::AddTodoWhenBuildFailsWorker)
              .not_to receive(:perform_async)

            subject
          end
        end
      end

      context 'when build has a chat' do
        before do
          build.pipeline.update!(source: :chat)
        end

        it 'schedules a ChatNotification job' do
          expect(ChatNotificationWorker).to receive(:perform_async).with(build.id)

          subject
        end
      end

      context 'when it has a database token' do
        before do
          stub_feature_flags(ci_job_token_jwt: false)
        end

        it 'removes the token' do
          expect { subject }.to change { build.reload.token }.to(nil)
        end
      end

      context 'and all conditions are correct for publishing provenance' do
        include_context 'with build, pipeline and artifacts'

        it 'calls PublishProvenanceWorker when build is successful' do
          expect(Ci::Slsa::PublishProvenanceWorker).to receive(:perform_async).with(build.id)

          subject
        end

        context 'and the build fails' do
          let_it_be(:status) { :failed }

          it 'still calls PublishProvenanceWorker' do
            expect(Ci::Slsa::PublishProvenanceWorker).to receive(:perform_async).with(build.id)

            subject
          end
        end

        context 'without build artifacts' do
          let(:build) do
            create(:ci_build, :finished, project: project)
          end

          it 'does not call PublishProvenanceWorker' do
            expect(Ci::Slsa::PublishProvenanceWorker).not_to receive(:perform_async)

            subject
          end
        end

        context 'without slsa_provenance_statement feature flag' do
          before do
            stub_feature_flags(slsa_provenance_statement: false)
          end

          it 'does not call PublishProvenanceWorker' do
            expect(Ci::Slsa::PublishProvenanceWorker).not_to receive(:perform_async).with(build.id)

            subject
          end
        end

        context 'without the GENERATE_PROVENANCE yaml variable' do
          let(:yaml_variables) { [] }

          it 'does not call PublishProvenanceWorker' do
            expect(Ci::Slsa::PublishProvenanceWorker).not_to receive(:perform_async)

            subject
          end
        end

        context 'without a public project' do
          let(:project) { create_default(:project, :private, :repository, group: group) }
          let(:build) do
            create(:ci_build, project: project)
          end

          it 'does not call PublishProvenanceWorker' do
            expect(Ci::Slsa::PublishProvenanceWorker).not_to receive(:perform_async)

            subject
          end
        end
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(non_existing_record_id) }
          .not_to raise_error
      end
    end
  end
end
