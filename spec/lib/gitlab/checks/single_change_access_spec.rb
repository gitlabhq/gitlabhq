# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::SingleChangeAccess, feature_category: :source_code_management do
  describe '#validate!' do
    include_context 'change access checks context'

    subject { change_access }

    context 'without failed checks' do
      it "doesn't raise an error" do
        expect { subject.validate! }.not_to raise_error
      end

      it 'calls pushes checks' do
        expect_next_instance_of(Gitlab::Checks::PushCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end

      it 'calls branches checks' do
        expect_next_instance_of(Gitlab::Checks::BranchCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end

      it 'calls tags checks' do
        expect_next_instance_of(Gitlab::Checks::TagCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end

      it 'calls diff checks' do
        expect_next_instance_of(Gitlab::Checks::DiffCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end
    end

    context 'when time limit was reached' do
      it 'raises a TimeoutError' do
        logger = Gitlab::Checks::TimedLogger.new(start_time: timeout.ago, timeout: timeout)
        access = described_class.new(
          changes,
          project: project,
          user_access: user_access,
          protocol: protocol,
          logger: logger
        )

        expect { access.validate! }.to raise_error(Gitlab::Checks::TimedLogger::TimeoutError)
      end
    end

    describe '#gitaly_context' do
      let(:access) do
        described_class.new(
          changes,
          project: project,
          user_access: user_access,
          protocol: protocol,
          logger: logger,
          gitaly_context: gitaly_context
        )
      end

      let(:gitaly_context) { { 'key' => 'value' } }

      it { expect(access.gitaly_context).to eq(gitaly_context) }
    end

    describe '#commits' do
      let(:expected_commits) { [Gitlab::Git::Commit.new(project.repository, { id: "1234" })] }

      let(:access) do
        described_class.new(
          changes,
          project: project,
          user_access: user_access,
          protocol: protocol,
          logger: logger,
          commits: provided_commits
        )
      end

      shared_examples '#commits' do
        it 'returns expected commits' do
          expect(access.commits).to eq(expected_commits)
        end

        it 'returns expected commits on repeated calls' do
          expect(access.commits).to eq(expected_commits)
          expect(access.commits).to eq(expected_commits)
        end
      end

      context 'with provided commits' do
        let(:provided_commits) { expected_commits }

        before do
          expect(project.repository).not_to receive(:new_commits)
        end

        it_behaves_like '#commits'
      end

      context 'without provided commits' do
        let(:provided_commits) { nil }

        before do
          expect(project.repository)
            .to receive(:new_commits)
            .with(newrev)
            .once
            .and_return(expected_commits)
        end

        it_behaves_like '#commits'
      end
    end
  end
end
