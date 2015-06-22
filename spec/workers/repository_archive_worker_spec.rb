require 'spec_helper'

describe RepositoryArchiveWorker do
  let(:project) { create(:project) }
  subject { RepositoryArchiveWorker.new }

  before do
    allow(Project).to receive(:find).and_return(project)
  end

  describe "#perform" do
    it "cleans old archives" do
      expect(project.repository).to receive(:clean_old_archives)

      subject.perform(project.id, "master", "zip")
    end

    context "when the repository doesn't have an archive file path" do
      before do
        allow(project.repository).to receive(:archive_file_path).and_return(nil)
      end

      it "doesn't archive the repo" do
        expect(project.repository).not_to receive(:archive_repo)

        subject.perform(project.id, "master", "zip")
      end
    end

    context "when the repository has an archive file path" do
      let(:file_path)     { "/archive.zip" }
      let(:pid_file_path) { "/archive.zip.pid" }

      before do
        allow(project.repository).to receive(:archive_file_path).and_return(file_path)
        allow(project.repository).to receive(:archive_pid_file_path).and_return(pid_file_path)
      end

      context "when the archive file already exists" do
        before do
          allow(File).to receive(:exist?).with(file_path).and_return(true)
        end

        it "doesn't archive the repo" do
          expect(project.repository).not_to receive(:archive_repo)

          subject.perform(project.id, "master", "zip")
        end
      end

      context "when the archive file doesn't exist yet" do
        before do
          allow(File).to receive(:exist?).with(file_path).and_return(false)
          allow(File).to receive(:exist?).with(pid_file_path).and_return(true)
        end

        context "when the archive pid file doesn't exist yet" do
          before do
            allow(File).to receive(:exist?).with(pid_file_path).and_return(false)
          end

          it "archives the repo" do
            expect(project.repository).to receive(:archive_repo)

            subject.perform(project.id, "master", "zip")
          end
        end

        context "when the archive pid file already exists" do
          it "doesn't archive the repo" do
            expect(project.repository).not_to receive(:archive_repo)

            subject.perform(project.id, "master", "zip")
          end
        end
      end
    end
  end
end
