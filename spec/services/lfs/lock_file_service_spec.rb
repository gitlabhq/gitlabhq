require 'spec_helper'

describe Lfs::LockFileService do
  let(:project)      { create(:project) }
  let(:current_user) { create(:user) }

  subject { described_class.new(project, current_user, params) }

  describe '#execute' do
    let(:params) { { path: 'README.md' } }

    context 'when not authorized' do
      it "doesn't succeed" do
        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(403)
        expect(result[:message]).to eq('You have no permissions')
      end
    end

    context 'when authorized' do
      before do
        project.add_developer(current_user)
      end

      context 'with an existent lock' do
        let!(:lock) { create(:lfs_file_lock, project: project) }

        it "doesn't succeed" do
          expect(subject.execute[:status]).to eq(:error)
        end

        it "doesn't create the Lock" do
          expect do
            subject.execute
          end.not_to change { LfsFileLock.count }
        end
      end

      context 'without an existent lock' do
        it "succeeds" do
          expect(subject.execute[:status]).to eq(:success)
        end

        it "creates the Lock" do
          expect do
            subject.execute
          end.to change { LfsFileLock.count }.by(1)
        end
      end

      context 'when an error is raised' do
        it "doesn't succeed" do
          allow_any_instance_of(described_class).to receive(:create_lock!).and_raise(StandardError)

          expect(subject.execute[:status]).to eq(:error)
        end
      end
    end
  end
end
