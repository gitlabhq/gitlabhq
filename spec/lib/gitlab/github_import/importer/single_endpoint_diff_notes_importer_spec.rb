# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::SingleEndpointDiffNotesImporter, feature_category: :importers do
  let(:client) { double }
  let(:project) { create(:project, import_source: 'github/repo') }

  subject { described_class.new(project, client) }

  it { is_expected.to include_module(Gitlab::GithubImport::ParallelScheduling) }
  it { is_expected.to include_module(Gitlab::GithubImport::SingleEndpointNotesImporting) }
  it { expect(subject.representation_class).to eq(Gitlab::GithubImport::Representation::DiffNote) }
  it { expect(subject.importer_class).to eq(Gitlab::GithubImport::Importer::DiffNoteImporter) }
  it { expect(subject.collection_method).to eq(:pull_request_comments) }
  it { expect(subject.object_type).to eq(:diff_note) }
  it { expect(subject.id_for_already_imported_cache({ id: 1 })).to eq(1) }

  describe '#each_object_to_import', :clean_gitlab_redis_shared_state do
    let(:merge_request) do
      create(
        :merged_merge_request,
        iid: 999,
        source_project: project,
        target_project: project
      )
    end

    let(:note) { { id: 1 } }
    let(:page) { instance_double(Gitlab::GithubImport::Client::Page, objects: [note], url: nil) }

    it 'fetches data' do
      expect(client)
        .to receive(:each_page)
        .exactly(:once) # ensure to be cached on the second call
        .with(:pull_request_comments, nil, 'github/repo', merge_request.iid, {})
        .and_yield(page)

      expect { |b| subject.each_object_to_import(&b) }.to yield_with_args(note)

      subject.each_object_to_import {}

      expect(
        Gitlab::Cache::Import::Caching.set_includes?(
          "github-importer/merge_request/diff_notes/already-imported/#{project.id}",
          merge_request.iid
        )
      ).to eq(true)
    end

    it 'resumes from the last processed URL' do
      resume_url = 'https://api.github.com/repositories/1/pulls/999/comments?page=2'

      Gitlab::Import::PageKeyset
        .new(project, "merge_request/#{merge_request.id}/pull_request_comments", ::Import::SOURCE_GITHUB)
        .set(resume_url)

      expect(client)
        .to receive(:each_page)
        .exactly(:once) # ensure to be cached on the second call
        .with(:pull_request_comments, resume_url, 'github/repo', merge_request.iid, {})

      subject.each_object_to_import {}
    end

    it 'skips cached merge requests' do
      Gitlab::Cache::Import::Caching.set_add(
        "github-importer/merge_request/diff_notes/already-imported/#{project.id}",
        merge_request.iid
      )

      expect(client).not_to receive(:each_page)

      subject.each_object_to_import {}
    end
  end
end
