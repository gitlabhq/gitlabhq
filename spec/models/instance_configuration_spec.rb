# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceConfiguration do
  context 'without cache' do
    describe '#settings' do
      describe '#ssh_algorithms_hashes' do
        let(:md5) { '5a:65:6c:4d:d4:4c:6d:e6:59:25:b8:cf:ba:34:e7:64' }
        let(:sha256) { 'SHA256:2KJDT7xf2i68mBgJ3TVsjISntg4droLbXYLfQj0VvSY' }

        it 'does not return anything if file does not exist' do
          stub_pub_file(pub_file(exist: false))

          expect(subject.settings[:ssh_algorithms_hashes]).to be_empty
        end

        it 'does not return anything if file is empty' do
          stub_pub_file(pub_file)

          stub_file_read(pub_file, content: '')

          expect(subject.settings[:ssh_algorithms_hashes]).to be_empty
        end

        it 'returns the md5 and sha256 if file valid and exists' do
          stub_pub_file(pub_file)

          result = subject.settings[:ssh_algorithms_hashes].select { |o| o[:md5] == md5 && o[:sha256] == sha256 }

          expect(result.size).to eq(InstanceConfiguration::SSH_ALGORITHMS.size)
        end

        it 'includes all algorithms' do
          stub_pub_file(pub_file)

          result = subject.settings[:ssh_algorithms_hashes]

          expect(result.map { |a| a[:name] }).to match_array(%w[DSA ECDSA ED25519 RSA])
        end

        it 'does not include disabled algorithm' do
          Gitlab::CurrentSettings.current_application_settings.update!(dsa_key_restriction: ApplicationSetting::FORBIDDEN_KEY_VALUE)
          stub_pub_file(pub_file)

          result = subject.settings[:ssh_algorithms_hashes]

          expect(result.map { |a| a[:name] }).to match_array(%w[ECDSA ED25519 RSA])
        end

        def pub_file(exist: true)
          path = exist ? 'spec/fixtures/ssh_host_example_key.pub' : 'spec/fixtures/ssh_host_example_key.pub.random'

          Rails.root.join(path)
        end

        def stub_pub_file(path)
          allow(subject).to receive(:ssh_algorithm_file).and_return(path)
        end
      end

      describe '#host' do
        it 'returns current instance host' do
          allow(Settings.gitlab).to receive(:host).and_return('exampledomain')

          expect(subject.settings[:host]).to eq(Settings.gitlab.host)
        end
      end

      describe '#gitlab_pages' do
        let(:gitlab_pages) { subject.settings[:gitlab_pages] }

        it 'returns Settings.pages' do
          gitlab_pages.delete(:ip_address)

          expect(gitlab_pages).to eq(Settings.pages.to_hash.deep_symbolize_keys)
        end

        it 'returns the GitLab\'s pages host ip address' do
          expect(gitlab_pages.keys).to include(:ip_address)
        end

        it 'returns the ip address as nil if the domain is invalid' do
          allow(Settings.pages).to receive(:host).and_return('exampledomain')

          expect(gitlab_pages[:ip_address]).to eq nil
        end

        it 'returns the ip address of the domain' do
          allow(Settings.pages).to receive(:host).and_return('localhost')

          expect(gitlab_pages[:ip_address]).to eq('127.0.0.1').or eq('::1')
        end
      end

      describe '#size_limits' do
        before do
          Gitlab::CurrentSettings.current_application_settings.update!(
            max_attachment_size: 10,
            receive_max_input_size: 20,
            max_import_size: 30,
            max_export_size: 40,
            diff_max_patch_bytes: 409600,
            max_artifacts_size: 50,
            max_pages_size: 60,
            snippet_size_limit: 70,
            max_import_remote_file_size: 80,
            bulk_import_max_download_file_size: 90
          )
        end

        it 'returns size limits from application settings' do
          size_limits = subject.settings[:size_limits]

          expect(size_limits[:max_attachment_size]).to eq(10.megabytes)
          expect(size_limits[:receive_max_input_size]).to eq(20.megabytes)
          expect(size_limits[:max_import_size]).to eq(30.megabytes)
          expect(size_limits[:max_export_size]).to eq(40.megabytes)
          expect(size_limits[:diff_max_patch_bytes]).to eq(400.kilobytes)
          expect(size_limits[:max_artifacts_size]).to eq(50.megabytes)
          expect(size_limits[:max_pages_size]).to eq(60.megabytes)
          expect(size_limits[:snippet_size_limit]).to eq(70.bytes)
          expect(size_limits[:max_import_remote_file_size]).to eq(80.megabytes)
          expect(size_limits[:bulk_import_max_download_file_size]).to eq(90.megabytes)
        end

        it 'returns nil if receive_max_input_size not set' do
          Gitlab::CurrentSettings.current_application_settings.update!(receive_max_input_size: nil)

          size_limits = subject.settings[:size_limits]

          expect(size_limits[:receive_max_input_size]).to be_nil
        end

        it 'returns nil if set to 0 (unlimited)' do
          Gitlab::CurrentSettings.current_application_settings.update!(
            max_import_size: 0,
            max_export_size: 0,
            max_pages_size: 0,
            max_import_remote_file_size: 0,
            bulk_import_max_download_file_size: 0
          )

          size_limits = subject.settings[:size_limits]

          expect(size_limits[:max_import_size]).to be_nil
          expect(size_limits[:max_export_size]).to be_nil
          expect(size_limits[:max_pages_size]).to be_nil
          expect(size_limits[:max_import_remote_file_size]).to eq(0)
          expect(size_limits[:bulk_import_max_download_file_size]).to eq(0)
        end
      end

      describe '#package_file_size_limits' do
        let_it_be(:plan1) { create(:plan, name: 'plan1', title: 'Plan 1') }
        let_it_be(:plan2) { create(:plan, name: 'plan2', title: 'Plan 2') }

        before do
          create(:plan_limits,
            plan: plan1,
            conan_max_file_size: 1001,
            helm_max_file_size: 1008,
            maven_max_file_size: 1002,
            npm_max_file_size: 1003,
            nuget_max_file_size: 1004,
            pypi_max_file_size: 1005,
            terraform_module_max_file_size: 1006,
            generic_packages_max_file_size: 1007
          )
          create(:plan_limits,
            plan: plan2,
            conan_max_file_size: 1101,
            helm_max_file_size: 1108,
            maven_max_file_size: 1102,
            npm_max_file_size: 1103,
            nuget_max_file_size: 1104,
            pypi_max_file_size: 1105,
            terraform_module_max_file_size: 1106,
            generic_packages_max_file_size: 1107
          )
        end

        it 'returns package file size limits' do
          file_size_limits = subject.settings[:package_file_size_limits]

          expect(file_size_limits[:Plan1]).to eq({ conan: 1001, helm: 1008, maven: 1002, npm: 1003, nuget: 1004, pypi: 1005, terraform_module: 1006, generic: 1007 })
          expect(file_size_limits[:Plan2]).to eq({ conan: 1101, helm: 1108, maven: 1102, npm: 1103, nuget: 1104, pypi: 1105, terraform_module: 1106, generic: 1107 })
        end
      end

      describe '#ci_cd_limits' do
        let_it_be(:plan1) { create(:plan, name: 'plan1', title: 'Plan 1') }
        let_it_be(:plan2) { create(:plan, name: 'plan2', title: 'Plan 2') }

        before do
          create(:plan_limits,
            plan: plan1,
            ci_pipeline_size: 1001,
            ci_active_jobs: 1002,
            ci_project_subscriptions: 1004,
            ci_pipeline_schedules: 1005,
            ci_needs_size_limit: 1006,
            ci_registered_group_runners: 1007,
            ci_registered_project_runners: 1008
          )
          create(:plan_limits,
            plan: plan2,
            ci_pipeline_size: 1101,
            ci_active_jobs: 1102,
            ci_project_subscriptions: 1104,
            ci_pipeline_schedules: 1105,
            ci_needs_size_limit: 1106,
            ci_registered_group_runners: 1107,
            ci_registered_project_runners: 1108
          )
        end

        it 'returns CI/CD limits' do
          ci_cd_size_limits = subject.settings[:ci_cd_limits]

          expect(ci_cd_size_limits[:Plan1]).to eq({
            ci_active_jobs: 1002,
            ci_needs_size_limit: 1006,
            ci_pipeline_schedules: 1005,
            ci_pipeline_size: 1001,
            ci_project_subscriptions: 1004,
            ci_registered_group_runners: 1007,
            ci_registered_project_runners: 1008
          })
          expect(ci_cd_size_limits[:Plan2]).to eq({
            ci_active_jobs: 1102,
            ci_needs_size_limit: 1106,
            ci_pipeline_schedules: 1105,
            ci_pipeline_size: 1101,
            ci_project_subscriptions: 1104,
            ci_registered_group_runners: 1107,
            ci_registered_project_runners: 1108
          })
        end
      end

      describe '#rate_limits' do
        before do
          Gitlab::CurrentSettings.current_application_settings.update!(
            throttle_unauthenticated_enabled: false,
            throttle_unauthenticated_requests_per_period: 1001,
            throttle_unauthenticated_period_in_seconds: 1002,
            throttle_authenticated_api_enabled: true,
            throttle_authenticated_api_requests_per_period: 1003,
            throttle_authenticated_api_period_in_seconds: 1004,
            throttle_authenticated_web_enabled: true,
            throttle_authenticated_web_requests_per_period: 1005,
            throttle_authenticated_web_period_in_seconds: 1006,
            throttle_protected_paths_enabled: true,
            throttle_protected_paths_requests_per_period: 1007,
            throttle_protected_paths_period_in_seconds: 1008,
            throttle_unauthenticated_packages_api_enabled: false,
            throttle_unauthenticated_packages_api_requests_per_period: 1009,
            throttle_unauthenticated_packages_api_period_in_seconds: 1010,
            throttle_authenticated_packages_api_enabled: true,
            throttle_authenticated_packages_api_requests_per_period: 1011,
            throttle_authenticated_packages_api_period_in_seconds: 1012,
            throttle_authenticated_git_lfs_enabled: true,
            throttle_authenticated_git_lfs_requests_per_period: 1022,
            throttle_authenticated_git_lfs_period_in_seconds: 1023,
            issues_create_limit: 1013,
            notes_create_limit: 1014,
            project_export_limit: 1015,
            project_download_export_limit: 1016,
            project_import_limit: 1017,
            group_export_limit: 1018,
            group_download_export_limit: 1019,
            group_import_limit: 1020,
            raw_blob_request_limit: 1021,
            search_rate_limit: 1022,
            search_rate_limit_unauthenticated: 1000,
            users_get_by_id_limit: 1023
          )
        end

        it 'returns rate limits from application settings' do
          rate_limits = subject.settings[:rate_limits]

          expect(rate_limits[:unauthenticated]).to eq({ enabled: false, requests_per_period: 1001, period_in_seconds: 1002 })
          expect(rate_limits[:authenticated_api]).to eq({ enabled: true, requests_per_period: 1003, period_in_seconds: 1004 })
          expect(rate_limits[:authenticated_web]).to eq({ enabled: true, requests_per_period: 1005, period_in_seconds: 1006 })
          expect(rate_limits[:protected_paths]).to eq({ enabled: true, requests_per_period: 1007, period_in_seconds: 1008 })
          expect(rate_limits[:unauthenticated_packages_api]).to eq({ enabled: false, requests_per_period: 1009, period_in_seconds: 1010 })
          expect(rate_limits[:authenticated_packages_api]).to eq({ enabled: true, requests_per_period: 1011, period_in_seconds: 1012 })
          expect(rate_limits[:authenticated_git_lfs_api]).to eq({ enabled: true, requests_per_period: 1022, period_in_seconds: 1023 })
          expect(rate_limits[:issue_creation]).to eq({ enabled: true, requests_per_period: 1013, period_in_seconds: 60 })
          expect(rate_limits[:note_creation]).to eq({ enabled: true, requests_per_period: 1014, period_in_seconds: 60 })
          expect(rate_limits[:project_export]).to eq({ enabled: true, requests_per_period: 1015, period_in_seconds: 60 })
          expect(rate_limits[:project_export_download]).to eq({ enabled: true, requests_per_period: 1016, period_in_seconds: 60 })
          expect(rate_limits[:project_import]).to eq({ enabled: true, requests_per_period: 1017, period_in_seconds: 60 })
          expect(rate_limits[:group_export]).to eq({ enabled: true, requests_per_period: 1018, period_in_seconds: 60 })
          expect(rate_limits[:group_export_download]).to eq({ enabled: true, requests_per_period: 1019, period_in_seconds: 60 })
          expect(rate_limits[:group_import]).to eq({ enabled: true, requests_per_period: 1020, period_in_seconds: 60 })
          expect(rate_limits[:raw_blob]).to eq({ enabled: true, requests_per_period: 1021, period_in_seconds: 60 })
          expect(rate_limits[:search_rate_limit]).to eq({ enabled: true, requests_per_period: 1022, period_in_seconds: 60 })
          expect(rate_limits[:search_rate_limit_unauthenticated]).to eq({ enabled: true, requests_per_period: 1000, period_in_seconds: 60 })
          expect(rate_limits[:users_get_by_id]).to eq({ enabled: true, requests_per_period: 1023, period_in_seconds: 600 })
        end
      end
    end
  end

  context 'with cache', :use_clean_rails_memory_store_caching do
    it 'caches settings content' do
      expect(Rails.cache.read(described_class::CACHE_KEY)).to be_nil

      settings = subject.settings

      expect(Rails.cache.read(described_class::CACHE_KEY)).to eq(settings)
    end

    describe 'cached settings' do
      before do
        subject.settings
      end

      it 'expires after EXPIRATION_TIME' do
        allow(Time).to receive(:now).and_return(Time.current + described_class::EXPIRATION_TIME)
        Rails.cache.cleanup

        expect(Rails.cache.read(described_class::CACHE_KEY)).to eq(nil)
      end
    end
  end
end
