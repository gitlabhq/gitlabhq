# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ChangesAccessLogger, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }

  let(:destination) { instance_double(Gitlab::AppJsonLogger, info: nil) }

  subject(:logger) do
    described_class.new(
      project: project,
      destination: destination
    )
  end

  before do
    stub_feature_flags(changes_access_logging: true)
  end

  describe '#instrument' do
    it "returns the block's value" do
      expect(logger.instrument(:single_access_checks) { 123 }).to eq(123)
    end

    it 'records the duration' do
      logger.instrument(:push_check) { nil }
      logger.commit(status: :ok)

      expect(destination).to have_received(:info).with(
        a_hash_including(
          'changes_access_check_durations' => contain_exactly(a_hash_including(name: :push_check,
            duration_s:  a_kind_of(Numeric)))
        )
      )
    end

    it 'accumulates durations for the same check name' do
      # instrument calls current_monotonic_time before and after yielding
      allow(described_class).to receive(:current_monotonic_time).and_return(
        0.0, 0.1,
        0.2, 0.4
      )

      new_logger = described_class.new(
        project: project,
        destination: destination
      )

      new_logger.instrument(:push_check) { nil }
      new_logger.instrument(:push_check) { nil }
      new_logger.commit(status: :ok)

      expect(destination).to have_received(:info).with(
        a_hash_including(
          'changes_access_check_durations' => contain_exactly(a_hash_including(name: :push_check, duration_s: 0.3))
        )
      )
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(changes_access_logging: false)
      end

      it "returns the block's value without recording" do
        new_logger = described_class.new(
          project: project,
          destination: destination
        )

        expect(destination).not_to receive(:info)
        expect(new_logger.instrument(:single_access_checks) { 123 }).to eq(123)
      end
    end
  end

  describe '#commit' do
    before do
      logger.instrument(:push_check) { nil }
      logger.instrument(:lfs_check) { nil }
    end

    it 'logs a structured message with all durations' do
      logger.commit(status: :ok)

      expect(destination).to have_received(:info).with(
        a_hash_including(
          'class' => 'Gitlab::Checks::ChangesAccessLogger',
          'project_id' => project.id,
          'status' => 'ok',
          'changes_access_check_durations' => contain_exactly(
            a_hash_including(name: :push_check, duration_s: a_kind_of(Numeric)),
            a_hash_including(name: :lfs_check, duration_s: a_kind_of(Numeric))
          )
        )
      )
    end

    it 'includes error information when status is denied' do
      logger.commit(status: :denied, error: 'Gitlab::GitAccess::ForbiddenError')

      expect(destination).to have_received(:info).with(
        a_hash_including(
          'status' => 'denied',
          'error' => 'Gitlab::GitAccess::ForbiddenError'
        )
      )
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(changes_access_logging: false)
      end

      it 'does not log' do
        new_logger = described_class.new(
          project: project,
          destination: destination
        )

        new_logger.commit(status: :ok)

        expect(destination).not_to have_received(:info)
      end
    end
  end
end
