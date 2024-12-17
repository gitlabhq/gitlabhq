# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::App::TableTruncateCheck, feature_category: :cell do
  context 'when running on single databases' do
    before do
      skip_if_database_exists(:ci)
      skip_if_database_exists(:sec)
    end

    describe '#skip?' do
      subject { described_class.new.skip? }

      it { is_expected.to eq(true) }
    end
  end

  context 'when running on multiple databases' do
    let(:needs_truncation) { true }

    before do
      skip_if_shared_database(:ci)
      skip_if_shared_database(:sec)

      instance_count = [
        database_exists?(:main),
        database_exists?(:ci),
        database_exists?(:sec)
      ].count(&:itself)

      allow_next_instances_of(Gitlab::Database::TablesTruncate, instance_count) do |instance|
        allow(instance).to receive(:needs_truncation?).and_return(needs_truncation)
      end
    end

    describe '#skip?' do
      subject { described_class.new.skip? }

      it { is_expected.to eq(false) }
    end

    describe '#check?' do
      subject { described_class.new.check? }

      context 'when TableTruncate returns false' do
        let(:needs_truncation) { false }

        it { is_expected.to eq(true) }
      end

      context 'when TableTruncate returns true' do
        let(:needs_truncation) { true }

        it { is_expected.to eq(false) }
      end
    end

    describe '#show_error' do
      let(:needs_truncation) { true }
      let(:checker) { described_class.new }

      before do
        checker.check?
      end

      subject(:show_error) { checker.show_error }

      it 'outputs error information' do
        truncate_tasks = %r{gitlab:db:truncate_legacy_tables:main\sgitlab:db:truncate_legacy_tables:ci\s+}
        truncate_tasks = %r{#{truncate_tasks}gitlab:db:truncate_legacy_tables:sec\s+} if database_exists?(:sec)

        expected = %r{
          Try\sfixing\sit:\s+
          sudo\s-u\s.+?\s-H\sbundle\sexec\srake\s
          #{truncate_tasks}
          For\smore\sinformation\ssee:\s+
          doc/development/database/multiple_databases.md\sin\ssection\s'Truncating\stables'\s+
          Please\sfix\sthe\serror\sabove\sand\srerun\sthe\schecks.\s+
        }x

        expect { show_error }.to output(expected).to_stdout
      end
    end
  end
end
