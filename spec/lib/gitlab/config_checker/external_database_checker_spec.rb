# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ConfigChecker::ExternalDatabaseChecker do
  describe '#check' do
    subject { described_class.check }

    context 'database version is not deprecated' do
      before do
        allow(described_class).to receive(:db_version_deprecated?).and_return(false)
      end

      it { is_expected.to be_empty }
    end

    context 'database version is deprecated' do
      before do
        allow(described_class).to receive(:db_version_deprecated?).and_return(true)
      end

      let(:notice_deprecated_database) do
        {
          type: 'warning',
            message: _('Note that PostgreSQL 11 will become the minimum required PostgreSQL version in GitLab 13.0 (May 2020). '\
                     'PostgreSQL 9.6 and PostgreSQL 10 will no longer be supported in GitLab 13.0. '\
                     'Please consider upgrading your PostgreSQL version (%{db_version}) soon.') % { db_version: Gitlab::Database.version.to_s }
        }
      end

      it 'reports deprecated database notices' do
        is_expected.to contain_exactly(notice_deprecated_database)
      end
    end
  end

  describe '#db_version_deprecated' do
    subject { described_class.db_version_deprecated? }

    context 'database version is not deprecated' do
      before do
        allow(Gitlab::Database).to receive(:version).and_return(11)
      end

      it { is_expected.to be false }
    end

    context 'database version is deprecated' do
      before do
        allow(Gitlab::Database).to receive(:version).and_return(10)
      end

      it { is_expected.to be true }
    end
  end
end
