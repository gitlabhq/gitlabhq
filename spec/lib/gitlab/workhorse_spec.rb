require 'spec_helper'

describe Gitlab::Workhorse, lib: true do
  let(:project) { create(:project) }
  let(:subject) { Gitlab::Workhorse }

  describe "#send_git_archive" do
    context "when the repository doesn't have an archive file path" do
      before do
        allow(project.repository).to receive(:archive_metadata).and_return(Hash.new)
      end

      it "raises an error" do
        expect { subject.send_git_archive(project, "master", "zip") }.to raise_error(RuntimeError)
      end
    end
  end
end
