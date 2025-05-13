# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetApiRateLimitsToZero, feature_category: :groups_and_projects do
  let(:application_settings) { table(:application_settings) }
  let(:migration) { described_class.new }

  let(:create_organization_api_limit) { 10 }

  before do
    application_settings.create!(rate_limits: { create_organization_api_limit: create_organization_api_limit })
  end

  describe '#up' do
    context 'when running on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'does not modify any rate limits' do
        expect { migration.up }.not_to change { application_settings.first.rate_limits }
      end
    end

    context 'when not running on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      context 'when both feature flags are enabled' do
        before do
          allow(migration).to receive(:feature_flag_enabled?).with(:rate_limit_groups_and_projects_api).and_return(true)
          allow(migration).to receive(:feature_flag_enabled?).with(:rate_limiting_user_endpoints).and_return(true)
        end

        it 'does not modify any rate limits' do
          expect { migration.up }.not_to change { application_settings.first.rate_limits }
        end
      end

      context 'when rate_limit_groups_and_projects_api is disabled' do
        before do
          allow(migration).to receive(:feature_flag_enabled?).with(:rate_limit_groups_and_projects_api)
                                                             .and_return(false)
          allow(migration).to receive(:feature_flag_enabled?).with(:rate_limiting_user_endpoints).and_return(true)
        end

        it 'sets only groups and projects API rate limits to zero' do
          migration.up

          settings = application_settings.first
          expect(settings.rate_limits).to include(
            'group_api_limit' => 0,
            'group_projects_api_limit' => 0,
            'group_shared_groups_api_limit' => 0,
            'groups_api_limit' => 0,
            'project_api_limit' => 0,
            'projects_api_limit' => 0,
            'user_contributed_projects_api_limit' => 0,
            'user_projects_api_limit' => 0,
            'user_starred_projects_api_limit' => 0
          )

          # Users API limits should not be set
          expect(settings.rate_limits).not_to include(
            'users_api_limit_followers',
            'users_api_limit_following',
            'users_api_limit_status',
            'users_api_limit_ssh_keys',
            'users_api_limit_ssh_key',
            'users_api_limit_gpg_keys',
            'users_api_limit_gpg_key'
          )
        end
      end

      context 'when rate_limiting_user_endpoints is disabled' do
        before do
          allow(migration).to receive(:feature_flag_enabled?).with(:rate_limit_groups_and_projects_api).and_return(true)
          allow(migration).to receive(:feature_flag_enabled?).with(:rate_limiting_user_endpoints).and_return(false)
        end

        it 'sets only users API rate limits to zero' do
          migration.up

          settings = application_settings.first
          expect(settings.rate_limits).to include(
            'users_api_limit_followers' => 0,
            'users_api_limit_following' => 0,
            'users_api_limit_status' => 0,
            'users_api_limit_ssh_keys' => 0,
            'users_api_limit_ssh_key' => 0,
            'users_api_limit_gpg_keys' => 0,
            'users_api_limit_gpg_key' => 0
          )

          # Groups and projects API limits should not be set
          expect(settings.rate_limits).not_to include(
            'group_api_limit',
            'group_projects_api_limit',
            'group_shared_groups_api_limit',
            'groups_api_limit',
            'project_api_limit',
            'projects_api_limit',
            'user_contributed_projects_api_limit',
            'user_projects_api_limit',
            'user_starred_projects_api_limit'
          )
        end
      end

      context 'when both feature flags are disabled' do
        before do
          allow(migration).to receive(:feature_flag_enabled?).with(:rate_limit_groups_and_projects_api)
                                                             .and_return(false)
          allow(migration).to receive(:feature_flag_enabled?).with(:rate_limiting_user_endpoints).and_return(false)
        end

        it 'sets all API rate limits to zero' do
          migration.up

          settings = application_settings.first
          expect(settings.rate_limits).to include(
            # Groups and projects API limits
            'group_api_limit' => 0,
            'group_projects_api_limit' => 0,
            'group_shared_groups_api_limit' => 0,
            'groups_api_limit' => 0,
            'project_api_limit' => 0,
            'projects_api_limit' => 0,
            'user_contributed_projects_api_limit' => 0,
            'user_projects_api_limit' => 0,
            'user_starred_projects_api_limit' => 0,

            # Users API limits
            'users_api_limit_followers' => 0,
            'users_api_limit_following' => 0,
            'users_api_limit_status' => 0,
            'users_api_limit_ssh_keys' => 0,
            'users_api_limit_ssh_key' => 0,
            'users_api_limit_gpg_keys' => 0,
            'users_api_limit_gpg_key' => 0
          )
        end

        it 'does not change other rate limits' do
          migration.up

          settings = application_settings.first
          expect(settings.rate_limits).to include('create_organization_api_limit' => create_organization_api_limit)
        end
      end
    end
  end

  describe '#down' do
    it 'does not modify any rate limits' do
      expect { migration.down }.not_to change { application_settings.first.rate_limits }
    end
  end
end
