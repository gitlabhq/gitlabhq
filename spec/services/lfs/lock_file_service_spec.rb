require 'spec_helper'

describe Lfs::LockFileService do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    let(:params) { { path: 'README.md' } }

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
