require 'spec_helper'

describe Projects::UpdateMirrorService do
  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:mirror_user) { project.owner }
  subject { described_class.new(project, mirror_user) }

  before do
    project.import_url = Project::UNKNOWN_IMPORT_URL
    project.mirror = true
    project.mirror_user = mirror_user
    project.save
  end

  describe "#execute" do
    it "fetches the upstream repository" do
      expect(project).to receive(:fetch_mirror)

      subject.execute
    end

    it "succeeds" do
      allow(project).to receive(:fetch_mirror) { fetch_mirror(repository) }

      result = subject.execute

      expect(result[:status]).to eq(:success)
    end

    describe "updating tags" do
      it "creates new tags" do
        allow(project).to receive(:fetch_mirror) { fetch_mirror(repository) }

        subject.execute

        expect(repository.tag_names).to include('new-tag')
      end
    end

    describe "updating branches" do
      it "creates new branches" do
        allow(project).to receive(:fetch_mirror) { fetch_mirror(repository) }

        subject.execute

        expect(repository.branch_names).to include('new-branch')
      end

      it "updates existing branches" do
        allow(project).to receive(:fetch_mirror) { fetch_mirror(repository) }

        subject.execute

        expect(repository.find_branch('existing-branch').target).to eq(repository.find_branch('master').target)
      end

      it "doesn't update diverged branches" do
        allow(project).to receive(:fetch_mirror) { fetch_mirror(repository) }

        subject.execute

        expect(repository.find_branch('markdown').target).not_to eq(repository.find_branch('master').target)
      end
    end

    describe "when the mirror user doesn't have access" do
      let(:mirror_user) { create(:user) }

      it "fails" do
        allow(project).to receive(:fetch_mirror) { fetch_mirror(repository) }

        result = subject.execute

        expect(result[:status]).to eq(:error)
      end
    end
  end

  def fetch_mirror(repository)
    rugged = repository.rugged
    masterrev = repository.find_branch('master').target

    parentrev = repository.commit(masterrev).parent_id
    rugged.references.create('refs/heads/existing-branch', parentrev)

    repository.expire_branches_cache
    repository.branches

    # New branch
    rugged.references.create('refs/remotes/upstream/new-branch', masterrev)

    # Updated existing branch
    rugged.references.create('refs/remotes/upstream/existing-branch', masterrev)

    # Diverged branch
    rugged.references.create('refs/remotes/upstream/markdown', masterrev)

    # New tag
    rugged.references.create('refs/tags/new-tag', masterrev)
  end
end
