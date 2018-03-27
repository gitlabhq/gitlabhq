require 'spec_helper'

describe Gitlab::GithubImport::Importer::DiffNotesImporter do
  let(:project) { double(:project, id: 4, import_source: 'foo/bar') }
  let(:client) { double(:client) }

  let(:github_comment) do
    double(
      :response,
      html_url: 'https://github.com/foo/bar/pull/42',
      path: 'README.md',
      commit_id: '123abc',
      diff_hunk: "@@ -1 +1 @@\n-Hello\n+Hello world",
      user: double(:user, id: 4, login: 'alice'),
      body: 'Hello world',
      created_at: Time.zone.now,
      updated_at: Time.zone.now,
      id: 1
    )
  end

  describe '#parallel?' do
    it 'returns true when running in parallel mode' do
      importer = described_class.new(project, client)
      expect(importer).to be_parallel
    end

    it 'returns false when running in sequential mode' do
      importer = described_class.new(project, client, parallel: false)
      expect(importer).not_to be_parallel
    end
  end

  describe '#execute' do
    context 'when running in parallel mode' do
      it 'imports diff notes in parallel' do
        importer = described_class.new(project, client)

        expect(importer).to receive(:parallel_import)

        importer.execute
      end
    end

    context 'when running in sequential mode' do
      it 'imports diff notes in sequence' do
        importer = described_class.new(project, client, parallel: false)

        expect(importer).to receive(:sequential_import)

        importer.execute
      end
    end
  end

  describe '#sequential_import' do
    it 'imports each diff note in sequence' do
      importer = described_class.new(project, client, parallel: false)
      diff_note_importer = double(:diff_note_importer)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(github_comment)

      expect(Gitlab::GithubImport::Importer::DiffNoteImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::DiffNote),
          project,
          client
        )
        .and_return(diff_note_importer)

      expect(diff_note_importer).to receive(:execute)

      importer.sequential_import
    end
  end

  describe '#parallel_import' do
    it 'imports each diff note in parallel' do
      importer = described_class.new(project, client)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(github_comment)

      expect(Gitlab::GithubImport::ImportDiffNoteWorker)
        .to receive(:perform_async)
        .with(project.id, an_instance_of(Hash), an_instance_of(String))

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(1)
    end
  end

  describe '#id_for_already_imported_cache' do
    it 'returns the ID of the given note' do
      importer = described_class.new(project, client)

      expect(importer.id_for_already_imported_cache(github_comment))
        .to eq(1)
    end
  end

  describe '#collection_options' do
    it 'returns an empty Hash' do
      # For large projects (e.g. kubernetes/kubernetes) GitHub's API may produce
      # HTTP 500 errors when using explicit sorting options, regardless of what
      # order you sort in. Not using any sorting options at all allows us to
      # work around this.
      importer = described_class.new(project, client)

      expect(importer.collection_options).to eq({})
    end
  end
end
