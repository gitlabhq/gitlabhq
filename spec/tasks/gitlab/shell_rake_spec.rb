# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:shell rake tasks', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/shell'

    stub_warn_user_is_not_gitlab
  end

  describe 'install task' do
    it 'installs and compiles gitlab-shell' do
      expect_any_instance_of(Gitlab::TaskHelpers).to receive(:checkout_or_clone_version)
      allow(Kernel).to receive(:system).with('make', 'make_necessary_dirs', 'build').and_return(true)

      run_rake_task('gitlab:shell:install')
    end
  end

  describe 'setup task' do
    let!(:auth_key) { create(:key) }
    let!(:auth_and_signing_key) { create(:key, usage_type: :auth_and_signing) }

    before do
      create(:key, usage_type: :signing)

      allow(Gitlab::CurrentSettings).to receive(:authorized_keys_enabled?).and_return(write_to_authorized_keys)
    end

    context 'when "Write to authorized keys" is enabled' do
      let(:write_to_authorized_keys) { true }

      before do
        stub_env('force', force)
      end

      context 'when "force" is not set' do
        let(:force) { nil }

        context 'when the user answers "yes"' do
          it 'writes authorized keys into the file' do
            allow(main_object).to receive(:ask_to_continue)

            expect_next_instance_of(Gitlab::AuthorizedKeys) do |instance|
              expect(instance).to receive(:batch_add_keys).once do |keys|
                expect(keys).to match_array([auth_key, auth_and_signing_key])
              end
            end

            run_rake_task('gitlab:shell:setup')
          end
        end

        context 'when the user answers "no"' do
          it 'does not write authorized keys into the file' do
            allow(main_object).to receive(:ask_to_continue).and_raise(Gitlab::TaskAbortedByUserError)

            expect(Gitlab::AuthorizedKeys).not_to receive(:new)

            expect do
              run_rake_task('gitlab:shell:setup')
            end.to raise_error(SystemExit)
          end
        end
      end

      context 'when "force" is set to "yes"' do
        let(:force) { 'yes' }

        it 'writes authorized keys into the file' do
          expect_next_instance_of(Gitlab::AuthorizedKeys) do |instance|
            expect(instance).to receive(:batch_add_keys).once do |keys|
              expect(keys).to match_array([auth_key, auth_and_signing_key])
            end
          end

          run_rake_task('gitlab:shell:setup')
        end
      end
    end

    context 'when "Write to authorized keys" is disabled' do
      let(:write_to_authorized_keys) { false }

      it 'does not write authorized keys into the file' do
        expect(Gitlab::AuthorizedKeys).not_to receive(:new)

        run_rake_task('gitlab:shell:setup')
      end
    end
  end
end
