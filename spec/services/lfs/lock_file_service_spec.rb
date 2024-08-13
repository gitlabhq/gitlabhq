# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lfs::LockFileService, feature_category: :source_code_management do
  let(:project)      { create(:project) }
  let(:current_user) { create(:user) }

  describe '#execute' do
    subject(:execute) { described_class.new(project, current_user, params).execute }

    let(:params) { { path: 'README.md' } }

    context 'when not authorized' do
      it "doesn't succeed" do
        result = execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(403)
        expect(result[:message]).to eq('You have no permissions')
      end

      it_behaves_like 'does not refresh project.lfs_file_locks_changed_epoch'
    end

    context 'when authorized' do
      before do
        project.add_developer(current_user)
      end

      context 'with an existent lock' do
        let!(:lock) { create(:lfs_file_lock, project: project) }

        it "doesn't succeed" do
          expect(execute[:status]).to eq(:error)
        end

        it "doesn't create the Lock" do
          expect { execute }.not_to change { LfsFileLock.count }
        end

        it_behaves_like 'does not refresh project.lfs_file_locks_changed_epoch'
      end

      context 'without an existent lock' do
        it "succeeds" do
          expect(execute[:status]).to eq(:success)
        end

        it "creates the Lock" do
          expect { execute }.to change { LfsFileLock.count }.by(1)
        end

        it_behaves_like 'refreshes project.lfs_file_locks_changed_epoch value'
      end

      context 'when an error is raised' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:create_lock!).and_raise(StandardError)
          end
        end

        it "doesn't succeed" do
          expect(execute[:status]).to eq(:error)
        end

        it_behaves_like 'does not refresh project.lfs_file_locks_changed_epoch'
      end
    end
  end
end
