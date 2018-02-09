require 'spec_helper'

describe Gitlab::Checks::ForcePush do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository.raw }

  context "exit code checking", :skip_gitaly_mock do
    it "does not raise a runtime error if the `popen` call to git returns a zero exit code" do
      allow(repository).to receive(:popen).and_return(['normal output', 0])

      expect { described_class.force_push?(project, 'oldrev', 'newrev') }.not_to raise_error
    end

    it "raises a GitError error if the `popen` call to git returns a non-zero exit code" do
      allow(repository).to receive(:popen).and_return(['error', 1])

      expect { described_class.force_push?(project, 'oldrev', 'newrev') }
        .to raise_error(Gitlab::Git::Repository::GitError)
    end
  end
end
