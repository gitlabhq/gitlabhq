# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RunnerUpgradeCheck do
  using RSpec::Parameterized::TableSyntax

  describe '#check_runner_upgrade_status' do
    subject(:result) { described_class.instance.check_runner_upgrade_status(runner_version) }

    let(:gitlab_version) { '14.1.1' }

    before do
      allow(described_class.instance).to receive(:gitlab_version)
        .and_return(::Gitlab::VersionInfo.parse(gitlab_version))

      runner_releases_double = instance_double(Gitlab::Ci::RunnerReleases)

      allow(Gitlab::Ci::RunnerReleases).to receive(:instance).and_return(runner_releases_double)
      allow(runner_releases_double).to receive(:releases).and_return(available_runner_releases.map { |v| ::Gitlab::VersionInfo.parse(v) })
    end

    context 'with available_runner_releases configured up to 14.1.1' do
      let(:available_runner_releases) do
        %w[13.9.0 13.9.1 13.9.2 13.10.0 13.10.1 14.0.0 14.0.1 14.0.2-rc1 14.0.2 14.1.0 14.1.1]
      end

      context 'with nil runner_version' do
        let(:runner_version) { nil }

        it 'returns :invalid' do
          is_expected.to eq(:invalid)
        end
      end

      context 'with invalid runner_version' do
        let(:runner_version) { 'junk' }

        it 'returns :invalid' do
          is_expected.to eq(:invalid)
        end
      end

      context 'with Gitlab::VERSION set to 14.1.123' do
        let(:gitlab_version) { '14.1.123' }

        context 'with a runner_version that is too recent' do
          let(:runner_version) { 'v14.2.0' }

          it 'returns :not_available' do
            is_expected.to eq(:not_available)
          end
        end
      end

      context 'with Gitlab::VERSION set to 14.0.1' do
        let(:gitlab_version) { '14.0.1' }

        context 'with valid params' do
          where(:runner_version, :expected_result) do
            'v15.0.0'                      | :not_available # not available since the GitLab instance is still on 14.x, a major version might be incompatible, and a patch upgrade is not available
            'v14.1.0-rc3'                  | :recommended   # recommended since even though the GitLab instance is still on 14.0.x, there is a patch release (14.1.1) available which might contain security fixes
            'v14.1.0~beta.1574.gf6ea9389'  | :recommended   # suffixes are correctly handled
            'v14.1.0/1.1.0'                | :recommended   # suffixes are correctly handled
            'v14.1.0'                      | :recommended   # recommended since even though the GitLab instance is still on 14.0.x, there is a patch release (14.1.1) available which might contain security fixes
            'v14.0.1'                      | :recommended   # recommended upgrade since 14.0.2 is available
            'v14.0.2-rc1'                  | :recommended   # recommended upgrade since 14.0.2 is available and we'll move out of a release candidate
            'v14.0.2'                      | :not_available # not available since 14.0.2 is the latest 14.0.x release available within the instance's major.minor version
            'v13.10.1'                     | :available     # available upgrade: 14.1.1
            'v13.10.1~beta.1574.gf6ea9389' | :recommended   # suffixes are correctly handled, official 13.10.1 is available
            'v13.10.1/1.1.0'               | :recommended   # suffixes are correctly handled, official 13.10.1 is available
            'v13.10.0'                     | :recommended   # recommended upgrade since 13.10.1 is available
            'v13.9.2'                      | :recommended   # recommended upgrade since backports are no longer released for this version
            'v13.9.0'                      | :recommended   # recommended upgrade since backports are no longer released for this version
            'v13.8.1'                      | :recommended   # recommended upgrade since build is too old (missing in records)
            'v11.4.1'                      | :recommended   # recommended upgrade since build is too old (missing in records)
          end

          with_them do
            it 'returns symbol representing expected upgrade status' do
              is_expected.to be_a(Symbol)
              is_expected.to eq(expected_result)
            end
          end
        end
      end

      context 'with Gitlab::VERSION set to 13.9.0' do
        let(:gitlab_version) { '13.9.0' }

        context 'with valid params' do
          where(:runner_version, :expected_result) do
            'v14.0.0'                      | :recommended   # recommended upgrade since 14.0.2 is available, even though the GitLab instance is still on 13.x and a major version might be incompatible
            'v13.10.1'                     | :not_available # not available since 13.10.1 is already ahead of GitLab instance version and is the latest patch update for 13.10.x
            'v13.10.0'                     | :recommended   # recommended upgrade since 13.10.1 is available
            'v13.9.2'                      | :recommended   # recommended upgrade since backports are no longer released for this version
            'v13.9.0'                      | :recommended   # recommended upgrade since backports are no longer released for this version
            'v13.8.1'                      | :recommended   # recommended upgrade since build is too old (missing in records)
            'v11.4.1'                      | :recommended   # recommended upgrade since build is too old (missing in records)
          end

          with_them do
            it 'returns symbol representing expected upgrade status' do
              is_expected.to be_a(Symbol)
              is_expected.to eq(expected_result)
            end
          end
        end
      end
    end
  end
end
