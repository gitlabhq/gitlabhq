# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ConfigChecker::ExternalDatabaseChecker do
  describe '#check' do
    subject { described_class.check }

    let(:old_database_version) { 8 }
    let(:old_database) { instance_double(Gitlab::Database::Reflection) }
    let(:new_database) { instance_double(Gitlab::Database::Reflection) }

    before do
      allow(Gitlab::Database::Reflection).to receive(:new).and_return(new_database)
      allow(old_database).to receive(:postgresql_minimum_supported_version?).and_return(false)
      allow(old_database).to receive(:version).and_return(old_database_version)
      allow(new_database).to receive(:postgresql_minimum_supported_version?).and_return(true)
    end

    context 'with a single database' do
      before do
        skip_if_multiple_databases_are_setup
      end

      context 'when database meets minimum supported version' do
        before do
          allow(Gitlab::Database::Reflection).to receive(:new).with(ActiveRecord::Base).and_return(new_database)
        end

        it { is_expected.to be_empty }
      end

      context 'when database does not meet minimum supported version' do
        before do
          allow(Gitlab::Database::Reflection).to receive(:new).with(ActiveRecord::Base).and_return(old_database)
        end

        it 'reports deprecated database notice' do
          is_expected.to contain_exactly(notice_deprecated_database('main', old_database_version))
        end
      end
    end

    context 'with a multiple database' do
      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      context 'when both databases meets minimum supported version' do
        before do
          allow(Gitlab::Database::Reflection).to receive(:new).with(ActiveRecord::Base).and_return(new_database)
          allow(Gitlab::Database::Reflection).to receive(:new).with(Ci::ApplicationRecord).and_return(new_database)
        end

        it { is_expected.to be_empty }
      end

      context 'when the one of the databases does not meet minimum supported version' do
        it 'reports deprecated database notice if the main database is using an old version' do
          allow(Gitlab::Database::Reflection).to receive(:new).with(ActiveRecord::Base).and_return(old_database)
          allow(Gitlab::Database::Reflection).to receive(:new).with(Ci::ApplicationRecord).and_return(new_database)
          is_expected.to contain_exactly(notice_deprecated_database('main', old_database_version))
        end

        it 'reports deprecated database notice if the ci database is using an old version' do
          allow(Gitlab::Database::Reflection).to receive(:new).with(ActiveRecord::Base).and_return(new_database)
          allow(Gitlab::Database::Reflection).to receive(:new).with(Ci::ApplicationRecord).and_return(old_database)
          is_expected.to contain_exactly(notice_deprecated_database('ci', old_database_version))
        end
      end

      context 'when both databases do not meet minimum supported version' do
        before do
          allow(Gitlab::Database::Reflection).to receive(:new).with(ActiveRecord::Base).and_return(old_database)
          allow(Gitlab::Database::Reflection).to receive(:new).with(Ci::ApplicationRecord).and_return(old_database)
        end

        it 'reports deprecated database notice' do
          is_expected.to match_array [
            notice_deprecated_database('main', old_database_version),
            notice_deprecated_database('ci', old_database_version)
          ]
        end
      end
    end
  end

  def notice_deprecated_database(database_name, database_version)
    {
      type: 'warning',
      message: _(
        'Database \'%{database_name}\' is using PostgreSQL %{pg_version_current}, ' \
        'but this version of GitLab requires PostgreSQL %{pg_version_minimum}. ' \
        'Please upgrade your environment to a supported PostgreSQL version. ' \
        'See %{pg_requirements_url} for details.'
      ) % {
        database_name: database_name,
        pg_version_current: database_version,
        pg_version_minimum: Gitlab::Database::MINIMUM_POSTGRES_VERSION,
        pg_requirements_url: Gitlab::ConfigChecker::ExternalDatabaseChecker::PG_REQUIREMENTS_LINK
      }
    }
  end
end
