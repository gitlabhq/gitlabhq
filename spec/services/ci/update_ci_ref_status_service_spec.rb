# frozen_string_literal: true

require 'spec_helper'

describe Ci::UpdateCiRefStatusService do
  describe '#call' do
    subject { described_class.new(pipeline) }

    shared_examples 'creates ci_ref' do
      it 'creates a ci_ref with the pipeline attributes' do
        expect do
          expect(subject.call).to eq(true)
        end.to change { Ci::Ref.count }.by(1)

        created_ref = pipeline.reload.ref_status
        %w[ref tag project status].each do |attr|
          expect(created_ref[attr]).to eq(pipeline[attr])
        end
      end

      it 'calls PipelineNotificationWorker pasing the ref_status' do
        expect(PipelineNotificationWorker).to receive(:perform_async).with(pipeline.id, ref_status: pipeline.status)

        subject.call
      end
    end

    shared_examples 'updates ci_ref' do
      where(:ref_status, :pipeline_status, :next_status) do
        [
          %w[failed success fixed],
          %w[failed failed failed],
          %w[success success success],
          %w[success failed failed]
        ]
      end

      with_them do
        let(:ci_ref) { create(:ci_ref, status: ref_status) }
        let(:pipeline) { create(:ci_pipeline, status: pipeline_status, project: ci_ref.project, ref: ci_ref.ref) }

        it 'sets ci_ref.status to next_status' do
          expect do
            expect(subject.call).to eq(true)
            expect(ci_ref.reload.status).to eq(next_status)
          end.not_to change { Ci::Ref.count }
        end

        it 'calls PipelineNotificationWorker pasing the ref_status' do
          expect(PipelineNotificationWorker).to receive(:perform_async).with(pipeline.id, ref_status: next_status)

          subject.call
        end
      end
    end

    shared_examples 'does a noop' do
      it "doesn't change ci_ref" do
        expect do
          expect do
            expect(subject.call).to eq(false)
          end.not_to change { ci_ref.reload.status }
        end.not_to change { Ci::Ref.count }
      end

      it "doesn't call PipelineNotificationWorker" do
        expect(PipelineNotificationWorker).not_to receive(:perform_async)

        subject.call
      end
    end

    context "ci_ref doesn't exists" do
      let(:pipeline) { create(:ci_pipeline, :success, ref: 'new-ref') }

      it_behaves_like 'creates ci_ref'

      context 'when an ActiveRecord::RecordNotUnique validation is raised' do
        let(:ci_ref) { create(:ci_ref, status: 'failed') }
        let(:pipeline) { create(:ci_pipeline, status: :success, project: ci_ref.project, ref: ci_ref.ref) }

        it 'reloads the ci_ref and retries once' do
          subject.instance_variable_set("@ref", subject.send(:build_ref))

          expect do
            expect(subject.call).to eq(true)
          end.not_to change { Ci::Ref.count }
          expect(ci_ref.reload.status).to eq('fixed')
        end

        it 'raises error on multiple retries' do
          allow_any_instance_of(Ci::Ref).to receive(:update)
            .and_raise(ActiveRecord::RecordNotUnique)

          expect { subject.call }.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end
    end

    context 'ci_ref exists' do
      let!(:ci_ref) { create(:ci_ref, status: 'failed') }
      let(:pipeline) { ci_ref.pipelines.first }

      it_behaves_like 'updates ci_ref'

      context 'pipeline status is invalid' do
        let!(:pipeline) { create(:ci_pipeline, :running, project: ci_ref.project, ref: ci_ref.ref, tag: ci_ref.tag) }

        it_behaves_like 'does a noop'
      end

      context 'newer pipeline finished' do
        let(:newer_pipeline) { create(:ci_pipeline, :success, project: ci_ref.project, ref: ci_ref.ref, tag: ci_ref.tag) }

        before do
          ci_ref.update!(last_updated_by_pipeline: newer_pipeline)
        end

        it_behaves_like 'does a noop'
      end

      context 'pipeline is retried' do
        before do
          ci_ref.update!(last_updated_by_pipeline: pipeline)
        end

        it_behaves_like 'updates ci_ref'
      end

      context 'ref is stale' do
        let(:pipeline1) { create(:ci_pipeline, :success, project: ci_ref.project, ref: ci_ref.ref, tag: ci_ref.tag) }
        let(:pipeline2) { create(:ci_pipeline, :success, project: ci_ref.project, ref: ci_ref.ref, tag: ci_ref.tag) }

        it 'reloads the ref and retry' do
          service1 = described_class.new(pipeline1)
          service2 = described_class.new(pipeline2)

          service2.send(:ref)
          service1.call
          expect(ci_ref.reload.status).to eq('fixed')
          expect do
            expect(service2.call).to eq(true)
            # We expect 'success' in this case rather than 'fixed' because
            # the ref is correctly reloaded on stale error.
            expect(ci_ref.reload.status).to eq('success')
          end.not_to change { Ci::Ref.count }
        end

        it 'aborts when a newer pipeline finished' do
          service1 = described_class.new(pipeline1)
          service2 = described_class.new(pipeline2)

          service2.call
          expect do
            expect(service1.call).to eq(false)
            expect(ci_ref.reload.status).to eq('fixed')
          end.not_to change { Ci::Ref.count }
        end
      end

      context 'ref exists as both tag/branch and tag' do
        let(:pipeline) { create(:ci_pipeline, :failed, project: ci_ref.project, ref: ci_ref.ref, tag: true) }
        let!(:branch_pipeline) { create(:ci_pipeline, :success, project: ci_ref.project, ref: ci_ref.ref, tag: false) }

        it_behaves_like 'creates ci_ref'
      end
    end
  end
end
