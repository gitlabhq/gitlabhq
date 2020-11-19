# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::RunnerInstructions do
  using RSpec::Parameterized::TableSyntax

  let(:params) { {} }
  let(:user) { create(:user) }

  describe 'OS' do
    Gitlab::Ci::RunnerInstructions::OS.each do |name, subject|
      context name do
        it 'has the required fields' do
          expect(subject).to have_key(:human_readable_name)
          expect(subject).to have_key(:download_locations)
          expect(subject).to have_key(:install_script_template_path)
          expect(subject).to have_key(:runner_executable)
        end

        it 'has a valid script' do
          expect(File.read(subject[:install_script_template_path]).length).not_to eq(0)
        end
      end
    end
  end

  describe 'OTHER_ENVIRONMENTS' do
    Gitlab::Ci::RunnerInstructions::OTHER_ENVIRONMENTS.each do |name, subject|
      context name do
        it 'has the required fields' do
          expect(subject).to have_key(:human_readable_name)
          expect(subject).to have_key(:installation_instructions_url)
        end
      end
    end
  end

  describe '#install_script' do
    subject { described_class.new(current_user: user, **params) }

    context 'invalid params' do
      where(:current_params, :expected_error_message) do
        { os: nil, arch: nil }                        | 'Missing OS'
        { os: 'linux', arch: nil }                    | 'Missing arch'
        { os: nil, arch: 'amd64' }                    | 'Missing OS'
        { os: 'non_existing_os', arch: 'amd64' }      | 'Invalid OS'
        { os: 'linux', arch: 'non_existing_arch' }    | 'Architecture not found for OS'
        { os: 'windows', arch: 'non_existing_arch' }  | 'Architecture not found for OS'
      end

      with_them do
        let(:params) { current_params }

        it 'raises argument error' do
          result = subject.install_script

          expect(result).to be_nil
          expect(subject.errors).to include(expected_error_message)
        end
      end
    end

    context 'with valid params' do
      where(:os, :arch) do
        'linux'   | 'amd64'
        'linux'   | '386'
        'linux'   | 'arm'
        'linux'   | 'arm64'
        'windows' | 'amd64'
        'windows' | '386'
        'osx'     | 'amd64'
      end

      with_them do
        let(:params) { { os: os, arch: arch } }

        around do |example|
          # puma in production does not run from Rails.root, ensure file loading does not assume this
          Dir.chdir(Rails.root.join('tmp').to_s) do
            example.run
          end
        end

        it 'returns string containing correct params' do
          result = subject.install_script

          expect(result).to be_a(String)

          if os == 'osx'
            expect(result).to include("darwin-#{arch}")
          else
            expect(result).to include("#{os}-#{arch}")
          end
        end
      end
    end
  end

  describe '#register_command' do
    let(:params) { { os: 'linux', arch: 'foo' } }

    where(:commands) do
      Gitlab::Ci::RunnerInstructions::OS.map do |name, values|
        { name => values[:runner_executable] }
      end
    end

    context 'group' do
      let(:group) { create(:group) }

      subject { described_class.new(current_user: user, group: group, **params) }

      context 'user is owner' do
        before do
          group.add_owner(user)
        end

        with_them do
          let(:params) { { os: commands.each_key.first, arch: 'foo' } }

          it 'have correct configurations' do
            result = subject.register_command

            expect(result).to include("#{commands[commands.each_key.first]} register")
            expect(result).to include("--registration-token #{group.runners_token}")
            expect(result).to include("--url #{Gitlab::Routing.url_helpers.root_url(only_path: false)}")
          end
        end
      end

      context 'user is not owner' do
        where(:user_permission) do
          [:maintainer, :developer, :reporter, :guest]
        end

        with_them do
          before do
            create(:group_member, user_permission, group: group, user: user)
          end

          it 'raises error' do
            result = subject.register_command

            expect(result).to be_nil
            expect(subject.errors).to include("Gitlab::Access::AccessDeniedError")
          end
        end
      end
    end

    context 'project' do
      let(:project) { create(:project) }

      subject { described_class.new(current_user: user, project: project, **params) }

      context 'user is maintainer' do
        before do
          project.add_maintainer(user)
        end

        with_them do
          let(:params) { { os: commands.each_key.first, arch: 'foo' } }

          it 'have correct configurations' do
            result = subject.register_command

            expect(result).to include("#{commands[commands.each_key.first]} register")
            expect(result).to include("--registration-token #{project.runners_token}")
            expect(result).to include("--url #{Gitlab::Routing.url_helpers.root_url(only_path: false)}")
          end
        end
      end

      context 'user is not maintainer' do
        where(:user_permission) do
          [:developer, :reporter, :guest]
        end

        with_them do
          before do
            create(:project_member, user_permission, project: project, user: user)
          end

          it 'raises error' do
            result = subject.register_command

            expect(result).to be_nil
            expect(subject.errors).to include("Gitlab::Access::AccessDeniedError")
          end
        end
      end
    end

    context 'instance' do
      subject { described_class.new(current_user: user, **params) }

      context 'user is admin' do
        let(:user) { create(:user, :admin) }

        with_them do
          let(:params) { { os: commands.each_key.first, arch: 'foo' } }

          it 'have correct configurations' do
            result = subject.register_command

            expect(result).to include("#{commands[commands.each_key.first]} register")
            expect(result).to include("--registration-token #{Gitlab::CurrentSettings.runners_registration_token}")
            expect(result).to include("--url #{Gitlab::Routing.url_helpers.root_url(only_path: false)}")
          end
        end
      end

      context 'user is not admin' do
        it 'raises error' do
          result = subject.register_command

          expect(result).to be_nil
          expect(subject.errors).to include("Gitlab::Access::AccessDeniedError")
        end
      end
    end
  end
end
