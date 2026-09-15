# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PgAsh::Installer, feature_category: :database do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:installed) { true }

  subject(:installer) { described_class.new(connection) }

  before do
    allow(connection).to receive(:schema_exists?).with('ash').and_return(installed)
  end

  def statement_invalid(cause)
    ActiveRecord::StatementInvalid.new.tap do |error|
      allow(error).to receive(:cause).and_return(cause)
    end
  end

  describe '#install' do
    it 'applies the vendored script and returns the stamped version' do
      expect(connection).to receive(:execute).with(Gitlab::Database::PgAsh.install_sql)
      allow(connection).to receive(:execute).with(/FROM ash\.config/).and_return([{ 'version' => '2.0-beta1' }])

      expect(installer.install).to eq('2.0-beta1')
    end

    context 'when pg_ash is not installed yet' do
      let(:installed) { false }

      it 'applies the vendored script' do
        expect(connection).to receive(:execute).with(Gitlab::Database::PgAsh.install_sql)

        expect(installer.install).to be_nil
      end
    end

    context 'when a different version is installed' do
      before do
        allow(connection).to receive(:execute).with(/FROM ash\.config/).and_return([{ 'version' => '1.5' }])
      end

      it 'refuses to apply the script' do
        expect(connection).not_to receive(:execute).with(Gitlab::Database::PgAsh.install_sql)

        expect { installer.install }
          .to raise_error(described_class::VersionMismatchError, /pg_ash 1.5 is installed/)
      end

      it 'explains both ways forward' do
        expect { installer.install }
          .to raise_error(described_class::VersionMismatchError, /uninstall first.*migration chain/m)
      end
    end

    it 'raises a PermissionError explaining how to grant CREATE' do
      allow(connection).to receive(:execute).and_raise(statement_invalid(PG::InsufficientPrivilege.new))

      expect { installer.install }.to raise_error(described_class::PermissionError, /GRANT CREATE ON DATABASE/)
    end

    it 'lets unrelated statement errors through' do
      allow(connection).to receive(:execute).and_raise(statement_invalid(PG::SyntaxError.new))

      expect { installer.install }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe '#uninstall' do
    it 'drops the schema through the pg_ash uninstall function' do
      expect(connection).to receive(:execute).with("SELECT ash.uninstall('yes')")

      expect(installer.uninstall).to be(true)
    end

    context 'when pg_ash is not installed' do
      let(:installed) { false }

      it 'does nothing' do
        expect(connection).not_to receive(:execute)

        expect(installer.uninstall).to be(false)
      end
    end
  end

  describe '#status' do
    it 'returns the pg_ash metrics as a hash' do
      allow(connection).to receive(:execute).with(/FROM ash\.status\(\)/).and_return(
        [{ 'metric' => 'version', 'value' => '2.0-beta1' }, { 'metric' => 'sampling_enabled', 'value' => 'false' }]
      )

      expect(installer.status).to eq('version' => '2.0-beta1', 'sampling_enabled' => 'false')
    end

    context 'when pg_ash is not installed' do
      let(:installed) { false }

      it 'returns nil' do
        expect(installer.status).to be_nil
      end
    end
  end

  describe '#installed_version' do
    it 'reads the version stamped in ash.config' do
      allow(connection).to receive(:execute)
        .with(/FROM ash\.config/)
        .and_return([{ 'version' => '2.0-beta1' }])

      expect(installer.installed_version).to eq('2.0-beta1')
    end

    context 'when pg_ash is not installed' do
      let(:installed) { false }

      it 'returns nil' do
        expect(installer.installed_version).to be_nil
      end
    end
  end

  describe 'the vendored script' do
    it 'stamps the version that VENDORED_VERSION records' do
      expect(Gitlab::Database::PgAsh.install_sql)
        .to include("version                    text not null default '#{Gitlab::Database::PgAsh::VENDORED_VERSION}'")
    end
  end
end
