# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseWarnings, feature_category: :database do
  describe '.check_postgres_version_and_print_warning' do
    let(:reflect) { instance_spy(Gitlab::Database::Reflection) }

    subject { described_class.check_postgres_version_and_print_warning }

    before do
      allow(Gitlab::Database::Reflection)
        .to receive(:new)
        .and_return(reflect)
    end

    it 'prints a warning if not compliant with minimum postgres version' do
      allow(reflect).to receive(:postgresql_minimum_supported_version?).and_return(false)

      expect(Kernel)
        .to receive(:warn)
        .with(/You are using PostgreSQL/)
        .exactly(Gitlab::Database.database_base_models.length)
        .times

      subject
    end

    it 'does not print a warning if compliant with minimum postgres version' do
      allow(reflect).to receive(:postgresql_minimum_supported_version?).and_return(true)

      expect(Kernel).not_to receive(:warn).with(/You are using PostgreSQL/)

      subject
    end

    it 'does not print a warning in Rails runner environment' do
      allow(reflect).to receive(:postgresql_minimum_supported_version?).and_return(false)
      allow(Gitlab::Runtime).to receive(:rails_runner?).and_return(true)

      expect(Kernel).not_to receive(:warn).with(/You are using PostgreSQL/)

      subject
    end

    it 'ignores ActiveRecord errors' do
      allow(reflect).to receive(:postgresql_minimum_supported_version?).and_raise(ActiveRecord::ActiveRecordError)

      expect { subject }.not_to raise_error
    end

    it 'ignores Postgres errors' do
      allow(reflect).to receive(:postgresql_minimum_supported_version?).and_raise(PG::Error)

      expect { subject }.not_to raise_error
    end
  end

  describe '.check_single_connection_and_print_warning' do
    subject { described_class.check_single_connection_and_print_warning }

    it 'prints a warning if single connection' do
      allow(Gitlab::Database).to receive(:database_mode).and_return(Gitlab::Database::MODE_SINGLE_DATABASE)

      expect(Kernel).to receive(:warn).with(/Your database has a single connection/)

      subject
    end

    it 'does not print a warning if single ci connection' do
      allow(Gitlab::Database).to receive(:database_mode)
        .and_return(Gitlab::Database::MODE_SINGLE_DATABASE_CI_CONNECTION)

      expect(Kernel).not_to receive(:warn)

      subject
    end

    it 'does not print a warning if multiple connection' do
      allow(Gitlab::Database).to receive(:database_mode).and_return(Gitlab::Database::MODE_MULTIPLE_DATABASES)

      expect(Kernel).not_to receive(:warn)

      subject
    end

    it 'does not print a warning in Rails runner environment' do
      allow(Gitlab::Database).to receive(:database_mode).and_return(Gitlab::Database::MODE_SINGLE_DATABASE)
      allow(Gitlab::Runtime).to receive(:rails_runner?).and_return(true)

      expect(Kernel).not_to receive(:warn)

      subject
    end
  end
end
