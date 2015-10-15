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
        allow(project.repository).to receive(:archive_metadata).and_return(Hash.new)
      end

      it "raises an error" do
        expect { subject.execute(timeout: 0.0) }.to raise_error(RuntimeError)
      end
    end

  end
end
