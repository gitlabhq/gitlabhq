# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:lfs:remove_missing rake task', :silence_stdout, feature_category: :source_code_management do
  before do
    Rake.application.rake_require 'tasks/gitlab/lfs/remove_missing'
  end

  describe 'gitlab:lfs:remove_missing' do
    subject(:rake_task) { run_rake_task('gitlab:lfs:remove_missing') }

    let_it_be(:project) { create(:project) } # rubocop:disable RSpec/AvoidTestProf -- this is not a migration spec

    shared_examples 'exits with error' do
      it 'exits with error' do
        expect { rake_task }.to raise_error(SystemExit)
      end
    end

    describe 'environment variable info logging' do
      let!(:lfs_object) { create(:lfs_object, :with_file) }

      before do
        create(:lfs_objects_project, project: project, lfs_object: lfs_object)
      end

      it 'logs DRY_RUN value at start' do
        expect(Rails.logger).to receive(:info).with(/Running gitlab:lfs:remove_missing/)
        expect(Rails.logger).to receive(:info).with(/DRY_RUN=true/)
        allow(Rails.logger).to receive(:info) # Allow other info calls

        rake_task
      end
    end

    describe 'dry run behavior' do
      let!(:lfs_object_missing_file) { create(:lfs_object, :with_file) }

      before do
        create(:lfs_objects_project, project: project, lfs_object: lfs_object_missing_file)
        FileUtils.rm_f(lfs_object_missing_file.file.path)
      end

      it 'does not delete by default (dry run)' do
        expect { rake_task }.not_to change { LfsObject.count }
      end
    end

    describe 'server-wide confirmation prompt' do
      let!(:lfs_object) { create(:lfs_object, :with_file) }

      before do
        stub_env('DRY_RUN', 'false')
        create(:lfs_objects_project, project: project, lfs_object: lfs_object)
        FileUtils.rm_f(lfs_object.file.path)
      end

      context 'when user confirms with yes' do
        before do
          allow($stdin).to receive(:gets).and_return("yes\n")
        end

        it 'shows warning and proceeds with deletion' do
          expect { rake_task }.to output(/WARNING.*server-wide.*Type 'yes' to continue/i).to_stdout
          expect(LfsObject.exists?(lfs_object.id)).to be false
        end
      end

      context 'when user does not confirm' do
        before do
          allow($stdin).to receive(:gets).and_return("no\n")
        end

        it 'exits without deleting' do
          expect { rake_task }.to raise_error(SystemExit)
          expect(LfsObject.exists?(lfs_object.id)).to be true
        end
      end

      context 'when user enters empty input' do
        before do
          allow($stdin).to receive(:gets).and_return("\n")
        end

        it_behaves_like 'exits with error'
      end

      context 'when stdin returns nil (EOF)' do
        before do
          allow($stdin).to receive(:gets).and_return(nil)
        end

        it_behaves_like 'exits with error'
      end
    end

    describe 'logger configuration' do
      let!(:lfs_object) { create(:lfs_object, :with_file) }

      before do
        create(:lfs_objects_project, project: project, lfs_object: lfs_object)
      end

      context 'when in production environment' do
        before do
          allow(Rails.env).to receive_messages(development?: false, production?: true)
        end

        it 'creates a broadcast logger with stdout' do
          expect(ActiveSupport::BroadcastLogger).to receive(:new).with(
            instance_of(Logger),
            Rails.logger
          ).and_call_original

          rake_task
        end
      end

      context 'when in development environment' do
        before do
          allow(Rails.env).to receive_messages(development?: true, production?: false)
        end

        it 'creates a broadcast logger with stdout' do
          expect(ActiveSupport::BroadcastLogger).to receive(:new).with(
            instance_of(Logger),
            Rails.logger
          ).and_call_original

          rake_task
        end
      end
    end
  end
end
