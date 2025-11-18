# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Releaser, feature_category: :continuous_integration do
  let(:job) { build(:ci_build, options: { release: config[:release] }) }

  subject(:releaser) { described_class.new(job: job) }

  describe '#script' do
    subject(:script) { releaser.script }

    context 'all nodes' do
      let(:config) do
        {
          release: {
            name: 'Release $CI_COMMIT_SHA',
            description: 'Created using the release-cli $EXTRA_DESCRIPTION',
            tag_name: 'release-$CI_COMMIT_SHA',
            tag_message: 'Annotated tag message',
            ref: '$CI_COMMIT_SHA',
            milestones: %w[m1 m2 m3],
            released_at: '2020-07-15T08:00:00Z',
            assets: {
              links: [
                { name: 'asset1', url: 'https://example.com/assets/1', link_type: 'other', filepath: '/pretty/asset/1' },
                { name: 'asset2', url: 'https://example.com/assets/2' }
              ]
            }
          }
        }
      end

      assets_link1 = '{\"name\":\"asset1\",\"url\":\"https://example.com/assets/1\",\"link_type\":\"other\",\"filepath\":\"/pretty/asset/1\"}'
      assets_link2 = '{\"name\":\"asset2\",\"url\":\"https://example.com/assets/2\"}'
      glab_assets_links = "--assets-links \"[#{assets_link1},#{assets_link2}]\""
      release_cli_assets_links = "--assets-link \"#{assets_link1}\" --assets-link \"#{assets_link2}\""

      release_cli_command = 'release-cli create --name "Release $CI_COMMIT_SHA" --description "Created using the release-cli $EXTRA_DESCRIPTION" --tag-name "release-$CI_COMMIT_SHA" --tag-message "Annotated tag message" --ref "$CI_COMMIT_SHA" --released-at "2020-07-15T08:00:00Z" --milestone "m1" --milestone "m2" --milestone "m3"'

      glab_create_unix = 'glab release create -R $CI_PROJECT_PATH'
      glab_create_windows = 'glab release create -R $$env:CI_PROJECT_PATH'
      glab_command = "\"release-$CI_COMMIT_SHA\" #{glab_assets_links} --milestone \"m1,m2,m3\" --name \"Release $CI_COMMIT_SHA\" --experimental-notes-text-or-file \"Created using the release-cli $EXTRA_DESCRIPTION\" --ref \"$CI_COMMIT_SHA\" --tag-message \"Annotated tag message\" --released-at \"2020-07-15T08:00:00Z\" --no-update --no-close-milestone"

      warning_message = "Warning: release-cli will not be supported after 20.0. Please use glab version >= #{described_class::GLAB_REQUIRED_VERSION}. Troubleshooting: http://localhost/help/user/project/releases/_index.md#gitlab-cli-version-requirement"

      unix_result_for_glab_or_release_cli_without_catalog_publish = <<~BASH
      if command -v glab &> /dev/null; then
        if [ "$(printf "%s\\n%s" "#{described_class::GLAB_REQUIRED_VERSION}" "$(glab --version | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+')" | sort -V | head -n1)" = "#{described_class::GLAB_REQUIRED_VERSION}" ]; then
          #{described_class::GLAB_ENV_SET_UNIX}
          #{described_class::GLAB_CA_CERT_CONFIG_UNIX}
          #{described_class::GLAB_LOGIN_UNIX}
          #{glab_create_unix} #{glab_command}
          #{described_class::GLAB_CA_CERT_CLEANUP_UNIX}
        else
          echo "#{warning_message}"

          #{release_cli_command} #{release_cli_assets_links}
        fi
      else
        echo "#{warning_message}"

        #{release_cli_command} #{release_cli_assets_links}
      fi
      BASH
      windows_result_for_glab_or_release_cli_without_catalog_publish = <<~POWERSHELL
      if (Get-Command glab -ErrorAction SilentlyContinue) {
        $$glabVersionOutput = (glab --version | Select-Object -First 1) -as [string]

        if ($$glabVersionOutput -match 'glab (\\\d+\\\.\\\d+\\\.\\\d+)') {
          if ([version]$$matches[1] -ge [version]"#{described_class::GLAB_REQUIRED_VERSION}") {
            #{described_class::GLAB_ENV_SET_WINDOWS}
            #{described_class::GLAB_CA_CERT_CONFIG_WINDOWS}
            #{described_class::GLAB_LOGIN_WINDOWS}
            #{glab_create_windows} #{glab_command}
            #{described_class::GLAB_CA_CERT_CLEANUP_WINDOWS}
          }
          else {
            Write-Output "#{warning_message}"
            #{release_cli_command} #{release_cli_assets_links}
          }
        }
        else {
          Write-Output "#{warning_message}"
          #{release_cli_command} #{release_cli_assets_links}
        }
      }
      else {
        Write-Output "#{warning_message}"
        #{release_cli_command} #{release_cli_assets_links}
      }
      POWERSHELL

      context 'on different scenarios' do
        using RSpec::Parameterized::TableSyntax

        where(:runner_platform, :result) do
          'linux'      | unix_result_for_glab_or_release_cli_without_catalog_publish
          'windows'    | windows_result_for_glab_or_release_cli_without_catalog_publish
        end

        with_them do
          let(:runner_manager) { build(:ci_runner_machine, platform: runner_platform) }

          let(:job) do
            build(:ci_build,
              options: { release: config[:release] },
              runner: runner_manager.runner, runner_manager: runner_manager)
          end

          it { is_expected.to eq([result]) }
        end
      end

      context 'when project is a catalog resource' do
        let_it_be(:project) { create(:project, :catalog_resource_with_components) }
        let_it_be(:ci_catalog_resource) { create(:ci_catalog_resource, project: project) }
        let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

        unix_result_for_glab_or_release_cli_with_catalog_publish = <<~BASH
        if command -v glab &> /dev/null; then
          if [ "$(printf "%s\\n%s" "#{described_class::GLAB_REQUIRED_VERSION}" "$(glab --version | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+')" | sort -V | head -n1)" = "#{described_class::GLAB_REQUIRED_VERSION}" ]; then
            #{described_class::GLAB_ENV_SET_UNIX}
            #{described_class::GLAB_CA_CERT_CONFIG_UNIX}
            #{described_class::GLAB_LOGIN_UNIX}
            #{glab_create_unix} #{glab_command} --publish-to-catalog
            #{described_class::GLAB_CA_CERT_CLEANUP_UNIX}
          else
            echo "#{warning_message}"

            #{release_cli_command} #{release_cli_assets_links} --catalog-publish
          fi
        else
          echo "#{warning_message}"

          #{release_cli_command} #{release_cli_assets_links} --catalog-publish
        fi
        BASH
        windows_result_for_glab_or_release_cli_with_catalog_publish = <<~POWERSHELL
        if (Get-Command glab -ErrorAction SilentlyContinue) {
          $$glabVersionOutput = (glab --version | Select-Object -First 1) -as [string]

          if ($$glabVersionOutput -match 'glab (\\\d+\\\.\\\d+\\\.\\\d+)') {
            if ([version]$$matches[1] -ge [version]"#{described_class::GLAB_REQUIRED_VERSION}") {
              #{described_class::GLAB_ENV_SET_WINDOWS}
              #{described_class::GLAB_CA_CERT_CONFIG_WINDOWS}
              #{described_class::GLAB_LOGIN_WINDOWS}
              #{glab_create_windows} #{glab_command} --publish-to-catalog
              #{described_class::GLAB_CA_CERT_CLEANUP_WINDOWS}
            }
            else {
              Write-Output "#{warning_message}"
              #{release_cli_command} #{release_cli_assets_links} --catalog-publish
            }
          }
          else {
            Write-Output "#{warning_message}"
            #{release_cli_command} #{release_cli_assets_links} --catalog-publish
          }
        }
        else {
          Write-Output "#{warning_message}"
          #{release_cli_command} #{release_cli_assets_links} --catalog-publish
        }
        POWERSHELL

        context 'on different scenarios' do
          using RSpec::Parameterized::TableSyntax

          where(:catalog_publish_ff, :runner_platform, :result) do
            false | 'linux'      | unix_result_for_glab_or_release_cli_without_catalog_publish
            true  | 'linux'      | unix_result_for_glab_or_release_cli_with_catalog_publish
            false | 'windows'    | windows_result_for_glab_or_release_cli_without_catalog_publish
            true  | 'windows'    | windows_result_for_glab_or_release_cli_with_catalog_publish
          end

          with_them do
            let(:runner_manager) { build(:ci_runner_machine, platform: runner_platform) }

            let(:job) do
              build(:ci_build, pipeline: pipeline,
                options: { release: config[:release] },
                runner: runner_manager.runner, runner_manager: runner_manager)
            end

            before do
              stub_feature_flags(ci_release_cli_catalog_publish_option: catalog_publish_ff)
            end

            it { is_expected.to eq([result]) }
          end
        end
      end

      context 'with runner information' do
        let(:runner) { create(:ci_runner, :with_runner_manager) }
        let(:runner_manager) { runner.runner_managers.first }
        let(:job) { create(:ci_build, options: { release: config[:release] }, runner: runner, runner_manager: runner_manager) }

        it 'logs the runner information' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(
            class: described_class.to_s,
            message: 'The release script for the release build is being prepared.',
            runner_id: runner&.id,
            runner_type: runner&.runner_type,
            runner_platform: runner_manager&.platform
          )

          script
        end
      end
    end

    context 'individual nodes' do
      using RSpec::Parameterized::TableSyntax
      links = { links: [{ name: 'asset1', url: 'https://example.com/assets/1', link_type: 'other', filepath: '/pretty/asset/1' }] }

      where(:node_name, :node_value, :result) do
        :name        | 'Release $CI_COMMIT_SHA'         | 'glab release create -R $CI_PROJECT_PATH "$CI_COMMIT_TAG" --name "Release $CI_COMMIT_SHA" --ref "$CI_COMMIT_SHA"'
        :description | 'Release-cli $EXTRA_DESCRIPTION' | 'glab release create -R $CI_PROJECT_PATH "$CI_COMMIT_TAG" --experimental-notes-text-or-file "Release-cli $EXTRA_DESCRIPTION" --ref "$CI_COMMIT_SHA"'
        :tag_name    | 'release-$CI_COMMIT_SHA'         | 'glab release create -R $CI_PROJECT_PATH "release-$CI_COMMIT_SHA" --ref "$CI_COMMIT_SHA"'
        :tag_message | 'Annotated tag message'          | 'glab release create -R $CI_PROJECT_PATH "$CI_COMMIT_TAG" --ref "$CI_COMMIT_SHA" --tag-message "Annotated tag message"'
        :ref         | '$CI_COMMIT_SHA'                 | 'glab release create -R $CI_PROJECT_PATH "$CI_COMMIT_TAG" --ref "$CI_COMMIT_SHA"'
        :milestones  | %w[m1 m2 m3]                     | 'glab release create -R $CI_PROJECT_PATH "$CI_COMMIT_TAG" --milestone "m1,m2,m3" --ref "$CI_COMMIT_SHA"'
        :released_at | '2020-07-15T08:00:00Z'           | 'glab release create -R $CI_PROJECT_PATH "$CI_COMMIT_TAG" --ref "$CI_COMMIT_SHA" --released-at "2020-07-15T08:00:00Z"'
        :assets      | links                            | "glab release create -R $CI_PROJECT_PATH \"$CI_COMMIT_TAG\" --assets-links #{links[:links].to_json.to_json} --ref \"$CI_COMMIT_SHA\""
      end

      with_them do
        let(:config) do
          {
            release: {
              node_name => node_value
            }
          }
        end

        it 'generates the script' do
          expect(script).to match([a_string_including(result)])
        end
      end
    end
  end
end
