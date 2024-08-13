# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lfs::UnlockFileService, feature_category: :source_code_management do
  let(:project)      { create(:project) }
  let(:current_user) { create(:user) }
  let(:lock_author)  { create(:user) }
  let!(:lock)        { create(:lfs_file_lock, user: lock_author, project: project) }
  let(:params)       { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(project, current_user, params).execute }

    context 'when not authorized' do
      it "doesn't succeed" do
        result = execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(403)
        expect(result[:message]).to eq(_('You have no permissions'))
      end

      it_behaves_like 'does not refresh project.lfs_file_locks_changed_epoch'
    end

    context 'when authorized' do
      before do
        project.add_developer(current_user)
      end

      context 'when lock does not exists' do
        let(:params) { { id: 123 } }

        it "doesn't succeed" do
          result = execute

          expect(result[:status]).to eq(:error)
          expect(result[:http_status]).to eq(404)
        end

        it_behaves_like 'does not refresh project.lfs_file_locks_changed_epoch'
      end

      context 'when unlocked by the author' do
        let(:current_user) { lock_author }
        let(:params) { { id: lock.id } }

        it "succeeds" do
          result = execute

          expect(result[:status]).to eq(:success)
          expect(result[:lock]).to be_present
        end

        it_behaves_like 'refreshes project.lfs_file_locks_changed_epoch value'
      end

      context 'when unlocked by a different user' do
        let(:current_user) { create(:user) }
        let(:params) { { id: lock.id } }

        it "doesn't succeed" do
          result = execute

          expect(result[:status]).to eq(:error)
          expect(result[:message]).to match(/'README.md' is locked by @#{lock_author.username}/)
          expect(result[:http_status]).to eq(403)
        end

        it_behaves_like 'does not refresh project.lfs_file_locks_changed_epoch'
      end

      context 'when forced' do
        let(:developer) { create(:user) }
        let(:maintainer) { create(:user) }

        before do
          project.add_developer(developer)
          project.add_maintainer(maintainer)
        end

        context 'by a regular user' do
          let(:current_user) { developer }
          let(:params) do
            { id: lock.id,
              force: true }
          end

          it "doesn't succeed" do
            result = execute

            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq(_('You must have maintainer access to force delete a lock'))
            expect(result[:http_status]).to eq(403)
          end

          it_behaves_like 'does not refresh project.lfs_file_locks_changed_epoch'
        end

        context 'by a maintainer user' do
          let(:current_user) { maintainer }
          let(:params) do
            { id: lock.id,
              force: true }
          end

          it "succeeds" do
            result = execute

            expect(result[:status]).to eq(:success)
            expect(result[:lock]).to be_present
          end

          it_behaves_like 'refreshes project.lfs_file_locks_changed_epoch value'
        end
      end
    end
  end
end
