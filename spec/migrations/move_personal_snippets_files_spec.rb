require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170612071012_move_personal_snippets_files.rb')

describe MovePersonalSnippetsFiles, :migration do
  let(:migration) { described_class.new }
  let(:test_dir) { File.join(Rails.root, "tmp", "tests", "move_snippet_files_test") }
  let(:uploads_dir) { File.join(test_dir, 'uploads') }
  let(:new_uploads_dir) { File.join(uploads_dir, '-', 'system') }

  let(:notes) { table(:notes) }
  let(:snippets) { table(:snippets) }
  let(:uploads) { table(:uploads) }

  let(:user) { table(:users).create!(email: 'user@example.com', projects_limit: 10) }
  let(:project) { table(:projects).create!(name: 'gitlab', namespace_id: 1) }

  before do
    allow(CarrierWave).to receive(:root).and_return(test_dir)
    allow(migration).to receive(:base_directory).and_return(test_dir)
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    allow(migration).to receive(:say)
  end

  describe "#up" do
    let(:snippet) do
      snippet = snippets.create!(author_id: user.id)
      create_upload('picture.jpg', snippet)
      snippet.update(description: markdown_linking_file('picture.jpg', snippet))
      snippet
    end

    let(:snippet_with_missing_file) do
      snippet = snippets.create!(author_id: user.id, project_id: project.id)
      create_upload('picture.jpg', snippet, create_file: false)
      snippet.update(description: markdown_linking_file('picture.jpg', snippet))
      snippet
    end

    it 'moves the files' do
      source_path = File.join(uploads_dir, model_file_path('picture.jpg', snippet))
      destination_path = File.join(new_uploads_dir, model_file_path('picture.jpg', snippet))

      migration.up

      expect(File.exist?(source_path)).to be_falsy
      expect(File.exist?(destination_path)).to be_truthy
    end

    describe 'updating the markdown' do
      it 'includes the new path when the file exists' do
        secret = "secret#{snippet.id}"
        file_location = "/uploads/-/system/personal_snippet/#{snippet.id}/#{secret}/picture.jpg"

        migration.up

        expect(snippet.reload.description).to include(file_location)
      end

      it 'does not update the markdown when the file is missing' do
        secret = "secret#{snippet_with_missing_file.id}"
        file_location = "/uploads/personal_snippet/#{snippet_with_missing_file.id}/#{secret}/picture.jpg"

        migration.up

        expect(snippet_with_missing_file.reload.description).to include(file_location)
      end

      it 'updates the note markdown' do
        secret = "secret#{snippet.id}"
        file_location = "/uploads/-/system/personal_snippet/#{snippet.id}/#{secret}/picture.jpg"
        markdown = markdown_linking_file('picture.jpg', snippet)
        note = notes.create!(noteable_id: snippet.id,
                             noteable_type: Snippet,
                             note: "with #{markdown}",
                             author_id: user.id)

        migration.up

        expect(note.reload.note).to include(file_location)
      end
    end
  end

  describe "#down" do
    let(:snippet) do
      snippet = snippets.create!(author_id: user.id)
      create_upload('picture.jpg', snippet, in_new_path: true)
      snippet.update(description: markdown_linking_file('picture.jpg', snippet, in_new_path: true))
      snippet
    end

    let(:snippet_with_missing_file) do
      snippet = snippets.create!(author_id: user.id)
      create_upload('picture.jpg', snippet, create_file: false, in_new_path: true)
      snippet.update(description: markdown_linking_file('picture.jpg', snippet, in_new_path: true))
      snippet
    end

    it 'moves the files' do
      source_path = File.join(new_uploads_dir, model_file_path('picture.jpg', snippet))
      destination_path = File.join(uploads_dir, model_file_path('picture.jpg', snippet))

      migration.down

      expect(File.exist?(source_path)).to be_falsey
      expect(File.exist?(destination_path)).to be_truthy
    end

    describe 'updating the markdown' do
      it 'includes the new path when the file exists' do
        secret = "secret#{snippet.id}"
        file_location = "/uploads/personal_snippet/#{snippet.id}/#{secret}/picture.jpg"

        migration.down

        expect(snippet.reload.description).to include(file_location)
      end

      it 'keeps the markdown as is when the file is missing' do
        secret = "secret#{snippet_with_missing_file.id}"
        file_location = "/uploads/-/system/personal_snippet/#{snippet_with_missing_file.id}/#{secret}/picture.jpg"

        migration.down

        expect(snippet_with_missing_file.reload.description).to include(file_location)
      end

      it 'updates the note markdown' do
        markdown = markdown_linking_file('picture.jpg', snippet, in_new_path: true)
        secret = "secret#{snippet.id}"
        file_location = "/uploads/personal_snippet/#{snippet.id}/#{secret}/picture.jpg"
        note = notes.create!(noteable_id: snippet.id,
                             noteable_type: Snippet,
                             note: "with #{markdown}",
                             author_id: user.id)

        migration.down

        expect(note.reload.note).to include(file_location)
      end
    end
  end

  describe '#update_markdown' do
    it 'escapes sql in the snippet description' do
      migration.instance_variable_set('@source_relative_location', '/uploads/personal_snippet')
      migration.instance_variable_set('@destination_relative_location', '/uploads/system/personal_snippet')

      secret = '123456789'
      filename = 'hello.jpg'
      snippet = snippets.create!(author_id: user.id)

      path_before = "/uploads/personal_snippet/#{snippet.id}/#{secret}/#{filename}"
      path_after = "/uploads/system/personal_snippet/#{snippet.id}/#{secret}/#{filename}"
      description_before = "Hello world; ![image](#{path_before})'; select * from users;"
      description_after = "Hello world; ![image](#{path_after})'; select * from users;"

      migration.update_markdown(snippet.id, secret, filename, description_before)

      expect(snippet.reload.description).to eq(description_after)
    end
  end

  def create_upload(filename, snippet, create_file: true, in_new_path: false)
    secret = "secret#{snippet.id}"
    absolute_path = if in_new_path
                      File.join(new_uploads_dir, model_file_path(filename, snippet))
                    else
                      File.join(uploads_dir, model_file_path(filename, snippet))
                    end

    if create_file
      FileUtils.mkdir_p(File.dirname(absolute_path))
      FileUtils.touch(absolute_path)
    end

    uploads.create!(model_id: snippet.id,
                    model_type: snippet.class,
                    path: "#{secret}/#{filename}",
                    uploader: PersonalFileUploader,
                    size: 100.kilobytes)
  end

  def markdown_linking_file(filename, snippet, in_new_path: false)
    markdown =  "![#{filename.split('.')[0]}]"
    markdown += '(/uploads'
    markdown += '/-/system' if in_new_path
    markdown += "/#{model_file_path(filename, snippet)})"
    markdown
  end

  def model_file_path(filename, snippet)
    secret = "secret#{snippet.id}"

    File.join('personal_snippet', snippet.id.to_s, secret, filename)
  end
end
