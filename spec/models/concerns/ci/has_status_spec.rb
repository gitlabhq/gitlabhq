# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::HasStatus, feature_category: :continuous_integration do
  context 'for scope with one status' do
    shared_examples 'having a job' do |status|
      %i[ci_build generic_commit_status].each do |type|
        context "when it's #{status} #{type} job" do
          let!(:job) { create(type, status) }

          describe ".#{status}" do
            it 'contains the job' do
              expect(CommitStatus.public_send(status).all)
                .to contain_exactly(job)
            end
          end

          describe '.relevant' do
            if status == :created
              it 'contains nothing' do
                expect(CommitStatus.relevant.all).to be_empty
              end
            else
              it 'contains the job' do
                expect(CommitStatus.relevant.all).to contain_exactly(job)
              end
            end
          end
        end
      end
    end

    %i[created waiting_for_callback waiting_for_resource preparing running pending success
      failed canceled skipped].each do |status|
      it_behaves_like 'having a job', status
    end
  end

  context 'for scope with more statuses' do
    shared_examples 'containing the job' do |status|
      %i[ci_build generic_commit_status].each do |type|
        context "when it's #{status} #{type} job" do
          let!(:job) { create(type, status) }

          it 'contains the job' do
            is_expected.to contain_exactly(job)
          end
        end
      end
    end

    shared_examples 'not containing the job' do |status|
      %i[ci_build generic_commit_status].each do |type|
        context "when it's #{status} #{type} job" do
          let!(:job) { create(type, status) }

          it 'contains nothing' do
            is_expected.to be_empty
          end
        end
      end
    end

    describe '.running_or_pending' do
      subject { CommitStatus.running_or_pending }

      %i[running pending].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[created failed success].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.executing' do
      subject { CommitStatus.executing }

      %i[running canceling].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[created failed success canceled].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.alive' do
      subject { CommitStatus.alive }

      %i[running pending waiting_for_callback waiting_for_resource preparing created canceling].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[canceled failed success].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.created_or_pending' do
      subject { CommitStatus.created_or_pending }

      %i[created pending].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[running failed success].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.finished' do
      subject { CommitStatus.finished }

      %i[success failed canceled].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[created running pending].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.cancelable' do
      subject { CommitStatus.cancelable }

      %i[running pending waiting_for_callback waiting_for_resource preparing created scheduled manual].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[failed success skipped canceled].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.manual' do
      subject { CommitStatus.manual }

      %i[manual].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[failed success skipped canceled].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.scheduled' do
      subject { CommitStatus.scheduled }

      %i[scheduled].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[failed success skipped canceled].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.complete' do
      subject { CommitStatus.complete }

      described_class::COMPLETED_STATUSES.each do |status|
        it_behaves_like 'containing the job', status
      end

      described_class::ACTIVE_STATUSES.each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.complete_or_manual' do
      subject { CommitStatus.complete_or_manual }

      (described_class::COMPLETED_STATUSES + [:manual]).each do |status|
        it_behaves_like 'containing the job', status
      end

      described_class::ACTIVE_STATUSES.each do |status|
        it_behaves_like 'not containing the job', status
      end
    end

    describe '.waiting_for_resource_or_upcoming' do
      subject { CommitStatus.waiting_for_resource_or_upcoming }

      %i[created scheduled waiting_for_resource].each do |status|
        it_behaves_like 'containing the job', status
      end

      %i[running failed success canceled].each do |status|
        it_behaves_like 'not containing the job', status
      end
    end
  end

  describe '::DEFAULT_STATUS' do
    it 'is a status created' do
      expect(described_class::DEFAULT_STATUS).to eq 'created'
    end
  end

  describe '::BLOCKED_STATUS' do
    it 'is a status manual' do
      expect(described_class::BLOCKED_STATUS).to eq %w[manual scheduled]
    end
  end

  describe 'blocked?' do
    subject { object.blocked? }

    %w[ci_pipeline ci_stage ci_build generic_commit_status].each do |type|
      context "when #{type}" do
        let(:object) { build(type, status: status) }

        context 'when status is scheduled' do
          let(:status) { :scheduled }

          it { is_expected.to be_truthy }
        end

        context 'when status is manual' do
          let(:status) { :manual }

          it { is_expected.to be_truthy }
        end

        context 'when status is created' do
          let(:status) { :created }

          it { is_expected.to be_falsy }
        end
      end
    end
  end
end
