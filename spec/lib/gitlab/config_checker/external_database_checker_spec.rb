# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ConfigChecker::ExternalDatabaseChecker do
  describe '#check' do
    subject { described_class.check }

    context 'when database meets minimum supported version' do
      before do
        allow(Gitlab::Database.main).to receive(:postgresql_minimum_supported_version?).and_return(true)
      end

      it { is_expected.to be_empty }
    end

    context 'when database does not meet minimum supported version' do
      before do
        allow(Gitlab::Database.main).to receive(:postgresql_minimum_supported_version?).and_return(false)
      end

      let(:notice_deprecated_database) do
        {
          type: 'warning',
          message: _('You are using PostgreSQL %{pg_version_current}, but PostgreSQL ' \
                     '%{pg_version_minimum} is required for this version of GitLab. ' \
                     'Please upgrade your environment to a supported PostgreSQL version, ' \
                     'see %{pg_requirements_url} for details.') % {
                                                                    pg_version_current: Gitlab::Database.main.version,
                                                                    pg_version_minimum: Gitlab::Database::MINIMUM_POSTGRES_VERSION,
                                                                    pg_requirements_url: '<a href="https://docs.gitlab.com/ee/install/requirements.html#database">database requirements</a>'
                                                                  }
        }
      end

      it 'reports deprecated database notice' do
        is_expected.to contain_exactly(notice_deprecated_database)
      end
    end
  end
end
