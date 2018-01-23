require 'spec_helper'

describe Lfs::UnlockFileService do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let!(:lock)   { create(:lfs_file_lock, user: user, project: project) }

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'when lock does not exists' do
      let(:params) { { id: 123 } }
      it "doesn't succeed" do
        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(404)
      end
    end

    context 'when unlocked by the author' do
      let(:params) { { id: lock.id } }

      it "succeeds" do
        result = subject.execute

        expect(result[:status]).to eq(:success)
        expect(result[:lock]).to be_present
      end
    end

    context 'when unlocked by a different user' do
      let(:user) { create(:user) }

      it "doesn't succeed" do
        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to match(/is locked by GitLab User #{user.id}/)
        expect(result[:http_status]).to eq(403)
      end
    end

    context 'when forced' do
      let(:developer) { create(:user) }
      let(:master)    { create(:user) }

      before do
        project.add_developer(developer)
        project.add_master(master)
      end

      context 'by a regular user' do
        let(:user) { developer }
        let(:params) do
          { id: lock.id,
            force: true }
        end

        it "doesn't succeed" do
          result = subject.execute

          expect(result[:status]).to eq(:error)
          expect(result[:message]).to match(/You must have master access/)
          expect(result[:http_status]).to eq(403)
        end
      end

      context 'by a master user' do
        let(:user) { developer }
        let(:params) do
          { id: lock.id,
            force: true }
        end

        it "succeeds" do
          result = subject.execute

          expect(result[:status]).to eq(:success)
          expect(result[:lock]).to be_present
        end
      end
    end
  end
end
