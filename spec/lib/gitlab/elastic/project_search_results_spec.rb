require 'spec_helper'

describe Gitlab::Elastic::ProjectSearchResults, lib: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Project.__elasticsearch__.create_index!

    @project = create(:project)
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Project.__elasticsearch__.delete_index!
  end

  let(:query) { 'hello world' }

  describe 'initialize with empty ref' do
    let(:results) { Gitlab::Elastic::ProjectSearchResults.new(@project.id, query, '') }

    it { expect(results.project).to eq(@project) }
    it { expect(results.repository_ref).to be_nil }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }
    let(:results) { Gitlab::Elastic::ProjectSearchResults.new(@project.id, query, ref) }

    it { expect(results.project).to eq(@project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end

  describe "search" do
    it "returns correct amounts" do
      project = create :project
      project1 = create :project

      project.repository.index_blobs
      project.repository.index_commits
      
      # Notes
      create :note, note: 'bla-bla term', project: project
      # The note in the project you have no access to
      create :note, note: 'bla-bla term', project: project1

      # Wiki
      project.wiki.create_page("index_page", "term")
      project.wiki.index_blobs
      project1.wiki.create_page("index_page", " term")
      project1.wiki.index_blobs

      Project.__elasticsearch__.refresh_index!

      result = Gitlab::Elastic::ProjectSearchResults.new(project.id, "term")
      expect(result.notes_count).to eq(1)
      expect(result.wiki_blobs_count).to eq(1)
      expect(result.blobs_count).to eq(1)

      result1 = Gitlab::Elastic::ProjectSearchResults.new(project.id, "initial")
      expect(result1.commits_count).to eq(1)
    end
  end
end
