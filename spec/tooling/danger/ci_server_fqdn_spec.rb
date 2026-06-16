# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/ci_server_fqdn'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::CiServerFqdn, feature_category: :tooling do
  include_context 'with dangerfile'

  subject(:ci_server_fqdn) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:all_changed_files) { ['.gitlab-ci.yml'] }
  let(:changed_lines) { [] }

  before do
    allow(fake_helper).to receive_messages(all_changed_files: all_changed_files, changed_lines: changed_lines)
  end

  describe '#check_ci_server_fqdn_usage' do
    subject(:check) { ci_server_fqdn.check_ci_server_fqdn_usage }

    context 'when no CI files are changed' do
      let(:all_changed_files) { ['app/models/user.rb', 'spec/models/user_spec.rb'] }

      it 'does not warn or add markdown' do
        expect(ci_server_fqdn).not_to receive(:warn)
        expect(ci_server_fqdn).not_to receive(:markdown)

        check
      end
    end

    context 'when a CI file is changed but does not add $CI_SERVER_FQDN' do
      let(:changed_lines) { ['+  script: echo hello', '-  script: echo world'] }

      it 'does not warn or add markdown' do
        expect(ci_server_fqdn).not_to receive(:warn)
        expect(ci_server_fqdn).not_to receive(:markdown)

        check
      end
    end

    context 'when a CI file removes $CI_SERVER_FQDN' do
      let(:changed_lines) { ['-  script: echo $CI_SERVER_FQDN'] }

      it 'does not warn or add markdown' do
        expect(ci_server_fqdn).not_to receive(:warn)
        expect(ci_server_fqdn).not_to receive(:markdown)

        check
      end
    end

    context 'when a CI file adds $CI_SERVER_FQDN' do
      let(:changed_lines) { ['+  script: echo $CI_SERVER_FQDN'] }

      it 'warns and adds markdown' do
        expect(ci_server_fqdn).to receive(:warn).with(/CI_SERVER_FQDN/)
        expect(ci_server_fqdn).to receive(:markdown).with(/CI_SERVER_FQDN/)

        check
      end
    end

    context 'when a CI file adds ${CI_SERVER_FQDN} (braces form)' do
      let(:changed_lines) { ['+  script: echo ${CI_SERVER_FQDN}'] }

      it 'warns and adds markdown' do
        expect(ci_server_fqdn).to receive(:warn).with(/CI_SERVER_FQDN/)
        expect(ci_server_fqdn).to receive(:markdown).with(/CI_SERVER_FQDN/)

        check
      end
    end

    context 'when a CI file changes a line containing $CI_SERVER_FQDN (net zero)' do
      let(:changed_lines) do
        [
          '-  script: echo $CI_SERVER_FQDN',
          '+  script: curl $CI_SERVER_FQDN'
        ]
      end

      it 'warns because a new + line with $CI_SERVER_FQDN was added' do
        expect(ci_server_fqdn).to receive(:warn)
        expect(ci_server_fqdn).to receive(:markdown)

        check
      end
    end

    context 'with .gitlab/ci/ files' do
      let(:all_changed_files) { ['.gitlab/ci/some-job.yml'] }
      let(:changed_lines) { ['+  script: echo $CI_SERVER_FQDN'] }

      it 'warns for files outside gitlab-com include directory' do
        expect(ci_server_fqdn).to receive(:warn)
        expect(ci_server_fqdn).to receive(:markdown)

        check
      end
    end

    context 'with files inside .gitlab/ci/includes/gitlab-com/' do
      let(:all_changed_files) { ['.gitlab/ci/includes/gitlab-com/deploy.yml'] }
      let(:changed_lines) { ['+  script: echo $CI_SERVER_FQDN'] }

      it 'does not warn for intentionally GitLab.com-specific files' do
        expect(ci_server_fqdn).not_to receive(:warn)
        expect(ci_server_fqdn).not_to receive(:markdown)

        check
      end
    end

    context 'with non-CI YAML files' do
      let(:all_changed_files) { ['config/database.yml', 'spec/fixtures/ci_server_fqdn.yml'] }
      let(:changed_lines) { ['+  script: echo $CI_SERVER_FQDN'] }

      it 'does not check non-CI YAML files' do
        expect(fake_helper).not_to receive(:changed_lines)

        check
      end
    end

    context 'with multiple CI files where only some add $CI_SERVER_FQDN' do
      let(:all_changed_files) { ['.gitlab-ci.yml', '.gitlab/ci/build.yml'] }

      before do
        allow(fake_helper).to receive(:changed_lines).with('.gitlab-ci.yml')
          .and_return(['+  script: echo $CI_SERVER_FQDN'])
        allow(fake_helper).to receive(:changed_lines).with('.gitlab/ci/build.yml')
          .and_return(['+  script: echo hello'])
      end

      it 'warns and lists only the affected file' do
        expect(ci_server_fqdn).to receive(:warn)
        expect(ci_server_fqdn).to receive(:markdown).with(/\.gitlab-ci\.yml/)

        check
      end
    end

    context 'with .gitlab-ci.yaml (alternative extension)' do
      let(:all_changed_files) { ['.gitlab-ci.yaml'] }
      let(:changed_lines) { ['+  script: echo $CI_SERVER_FQDN'] }

      it 'warns for .yaml extension as well' do
        expect(ci_server_fqdn).to receive(:warn)
        expect(ci_server_fqdn).to receive(:markdown)

        check
      end
    end
  end
end
