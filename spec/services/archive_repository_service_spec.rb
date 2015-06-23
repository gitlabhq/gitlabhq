require 'spec_helper'

describe ArchiveRepositoryService do
  let(:project) { create(:project) }
  subject { ArchiveRepositoryService.new(project, "master", "zip") }

  describe "#execute" do
    it "cleans old archives" do
      expect(project.repository).to receive(:clean_old_archives)

      subject.execute(timeout: 0.0)
    end

    context "when the repository doesn't have an archive file path" do
      before do
        allow(project.repository).to receive(:archive_file_path).and_return(nil)
      end

      it "raises an error" do
        expect { subject.execute(timeout: 0.0) }.to raise_error(RuntimeError)
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

        it "returns the file path" do
          expect(subject.execute(timeout: 0.0)).to eq(file_path)
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

          it "queues the RepositoryArchiveWorker" do
            expect(RepositoryArchiveWorker).to receive(:perform_async)

            subject.execute(timeout: 0.0)
          end
        end

        context "when the archive pid file already exists" do
          it "doesn't queue the RepositoryArchiveWorker" do
            expect(RepositoryArchiveWorker).not_to receive(:perform_async)

            subject.execute(timeout: 0.0)
          end
        end

        context "when the archive file exists after a little while" do
          before do
            Thread.new do
              sleep 0.1
              allow(File).to receive(:exist?).with(file_path).and_return(true)
            end
          end

          it "returns the file path" do
            expect(subject.execute(timeout: 0.2)).to eq(file_path)
          end
        end

        context "when the archive file doesn't exist after the timeout" do
          it "returns nil" do
            expect(subject.execute(timeout: 0.0)).to eq(nil)
          end
        end
      end
    end
  end
end
