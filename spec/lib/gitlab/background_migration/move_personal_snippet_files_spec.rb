require 'spec_helper'

describe Gitlab::BackgroundMigration::MovePersonalSnippetFiles do
  let(:test_dir) { File.join(Rails.root, 'tmp', 'tests', 'move_snippet_files_test') }
  let(:old_uploads_dir) { File.join('uploads', 'system', 'personal_snippet') }
  let(:new_uploads_dir) { File.join('uploads', '-', 'system', 'personal_snippet') }
  let(:snippet) do
    snippet = create(:personal_snippet)
    create_upload_for_snippet(snippet)
    snippet.update_attributes!(description: markdown_linking_file(snippet))
    snippet
  end

  let(:migration) { described_class.new }

  before do
    allow(migration).to receive(:base_directory) { test_dir }
  end

  describe '#perform' do
    it 'moves the file on the disk'  do
      expected_path = File.join(test_dir, new_uploads_dir, snippet.id.to_s, "secret#{snippet.id}", 'upload.txt')

      migration.perform(old_uploads_dir, new_uploads_dir)

      expect(File.exist?(expected_path)).to be_truthy
    end

    it 'updates the markdown of the snippet' do
      expected_path = File.join(new_uploads_dir, snippet.id.to_s, "secret#{snippet.id}", 'upload.txt')
      expected_markdown = "[an upload](#{expected_path})"

      migration.perform(old_uploads_dir, new_uploads_dir)

      expect(snippet.reload.description).to eq(expected_markdown)
    end

    it 'updates the markdown of notes' do
      expected_path = File.join(new_uploads_dir, snippet.id.to_s, "secret#{snippet.id}", 'upload.txt')
      expected_markdown = "with [an upload](#{expected_path})"

      note = create(:note_on_personal_snippet, noteable: snippet, note: "with #{markdown_linking_file(snippet)}")

      migration.perform(old_uploads_dir, new_uploads_dir)

      expect(note.reload.note).to eq(expected_markdown)
    end
  end

  def create_upload_for_snippet(snippet)
    snippet_path = path_for_file_in_snippet(snippet)
    path = File.join(old_uploads_dir, snippet.id.to_s, snippet_path)
    absolute_path = File.join(test_dir, path)

    FileUtils.mkdir_p(File.dirname(absolute_path))
    FileUtils.touch(absolute_path)

    create(:upload, model: snippet, path: snippet_path, uploader: PersonalFileUploader)
  end

  def path_for_file_in_snippet(snippet)
    secret = "secret#{snippet.id}"
    filename = 'upload.txt'

    File.join(secret, filename)
  end

  def markdown_linking_file(snippet)
    path = File.join(old_uploads_dir, snippet.id.to_s, path_for_file_in_snippet(snippet))
    "[an upload](#{path})"
  end
end
