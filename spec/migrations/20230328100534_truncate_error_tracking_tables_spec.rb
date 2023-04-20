# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe TruncateErrorTrackingTables, :migration, feature_category: :redis do
  let(:migration) { described_class.new }

  context 'when on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    context 'when using Main db' do
      it 'truncates the table' do
        expect(described_class.connection).to receive(:execute).with('TRUNCATE table error_tracking_errors CASCADE')

        migration.up
      end
    end

    context 'when uses CI db', migration: :gitlab_ci do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'does not truncate the table' do
        expect(described_class.connection).not_to receive(:execute).with('TRUNCATE table error_tracking_errors CASCADE')

        migration.up
      end
    end
  end

  context 'when on self-managed' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false)
    end

    context 'when using Main db' do
      it 'does not truncate the table' do
        expect(described_class.connection).not_to receive(:execute).with('TRUNCATE table error_tracking_errors CASCADE')

        migration.up
      end
    end

    context 'when uses CI db', migration: :gitlab_ci do
      it 'does not truncate the table' do
        expect(described_class.connection).not_to receive(:execute).with('TRUNCATE table error_tracking_errors CASCADE')

        migration.up
      end
    end
  end
end
