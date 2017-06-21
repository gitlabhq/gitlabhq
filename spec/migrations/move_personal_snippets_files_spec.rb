require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170612071012_move_personal_snippets_files.rb')

describe MovePersonalSnippetsFiles do
  let(:migration) { described_class.new }
  let(:test_dir) { File.join(Rails.root, "tmp", "tests", "move_snippet_files_test") }
  let(:uploads_dir) { File.join(test_dir, 'uploads') }
  let(:new_uploads_dir) { File.join(uploads_dir, 'system') }

  let(:snippets) { create_list(:personal_snippet, 5) }

  let(:files) do
    [
      { name: 'picture.jpg', snippet: snippets[0] },
      { name: 'text_file.txt', snippet: snippets[1] },
      { name: 'another_text_file.txt', snippet: snippets[2], skip_description_update: true },
      { name: 'note_text.txt', snippet: snippets[2], in_note: true },
      { name: 'non_existing_file.txt', snippet: snippets[3], skip_file_creation: true }
    ]
  end

  before do
    allow(CarrierWave).to receive(:root).and_return(test_dir)
    allow(migration).to receive(:base_directory).and_return(test_dir)
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    allow(migration).to receive(:say)
  end

  describe "#up" do
    before do
      @revert_mode = false

      FileUtils.mkdir_p(uploads_dir)
      files.each { |file| create_upload(file) }
    end

    it 'moves the files' do
      migration.up

      files.each do |file|
        old_path = File.join(uploads_dir, model_file_path(file))
        new_path = File.join(new_uploads_dir, model_file_path(file))

        unless file[:skip_file_creation]
          expect(File.exist?(old_path)).to be_falsey
          expect(File.exist?(new_path)).to be_truthy
        end
      end
    end

    describe 'updating the markdown' do
      before do
        migration.up
      end

      it 'includes the new path when the file exists' do
        files.values_at(0, 1).each do |file|
          snippet = file[:snippet]
          secret = "secret#{file[:snippet].id}"
          file_location = "/uploads/system/personal_snippet/#{snippet.id}/#{secret}/#{file[:name]}"

          expect(snippet.reload.description).to include(file_location)
        end
      end

      it 'does not include the new path when the file exists' do
        files.values_at(2, 4).each do |file|
          snippet = file[:snippet]
          secret = "secret#{file[:snippet].id}"
          file_location = "/uploads/system/personal_snippet/#{snippet.id}/#{secret}/#{file[:name]}"

          expect(snippet.reload.description).not_to include(file_location)
        end
      end

      it 'updates the note markdown' do
        files.values_at(3).each do |file|
          snippet = file[:snippet]
          secret = "secret#{file[:snippet].id}"
          file_location = "/uploads/system/personal_snippet/#{snippet.id}/#{secret}/#{file[:name]}"

          expect(snippet.notes[0].reload.note).to include(file_location)
        end
      end
    end
  end

  describe "#down" do
    before do
      @revert_mode = true

      FileUtils.mkdir_p(uploads_dir)
      files.each { |file| create_upload(file) }
    end

    it 'moves the files' do
      migration.down

      files.each do |file|
        old_path = File.join(new_uploads_dir, model_file_path(file))
        new_path = File.join(uploads_dir, model_file_path(file))

        unless file[:skip_file_creation]
          expect(File.exist?(old_path)).to be_falsey
          expect(File.exist?(new_path)).to be_truthy
        end
      end
    end

    describe 'updating the markdown' do
      before do
        migration.down
      end

      it 'includes the new path when the file exists' do
        files.values_at(0, 1).each do |file|
          snippet = file[:snippet]
          secret = "secret#{file[:snippet].id}"
          file_location = "/uploads/personal_snippet/#{snippet.id}/#{secret}/#{file[:name]}"

          expect(snippet.reload.description).to include(file_location)
        end
      end

      it 'does not include the new path when the file exists' do
        files.values_at(2, 4).each do |file|
          snippet = file[:snippet]
          secret = "secret#{file[:snippet].id}"
          file_location = "/uploads/personal_snippet/#{snippet.id}/#{secret}/#{file[:name]}"

          expect(snippet.reload.description).not_to include(file_location)
        end
      end

      it 'updates the note markdown' do
        files.values_at(3).each do |file|
          snippet = file[:snippet]
          secret = "secret#{file[:snippet].id}"
          file_location = "/uploads/personal_snippet/#{snippet.id}/#{secret}/#{file[:name]}"

          expect(snippet.notes[0].reload.note).to include(file_location)
        end
      end
    end
  end

  describe '#update_markdown' do
    it 'escapes sql in the snippet description' do
      migration.instance_variable_set('@source_relative_location', '/uploads/personal_snippet')
      migration.instance_variable_set('@destination_relative_location', '/uploads/system/personal_snippet')

      secret = '123456789'
      filename = 'hello.jpg'
      snippet = create(:personal_snippet)

      path_before = "/uploads/personal_snippet/#{snippet.id}/#{secret}/#{filename}"
      path_after = "/uploads/system/personal_snippet/#{snippet.id}/#{secret}/#{filename}"
      description_before = "Hello world; ![image](#{path_before})'; select * from users;"
      description_after = "Hello world; ![image](#{path_after})'; select * from users;"

      migration.update_markdown(snippet.id, secret, filename, description_before)

      expect(snippet.reload.description).to eq(description_after)
    end
  end

  def create_upload(file)
    snippet = file[:snippet]
    secret = "secret#{snippet.id}"
    absolute_path = if @revert_mode
                      File.join(new_uploads_dir, model_file_path(file))
                    else
                      File.join(uploads_dir, model_file_path(file))
                    end

    markdown = file[:name].include?('.jpg') ? "![#{file[:name].split('.')[0]}]" : "[#{file[:name]}]"
    markdown += '(/uploads'
    markdown += '/system' if @revert_mode
    markdown += "/#{model_file_path(file)})"

    unless file[:skip_file_creation]
      FileUtils.mkdir_p(File.dirname(absolute_path))
      FileUtils.touch(absolute_path)
    end

    create(:upload, model: file[:snippet], path: "#{secret}/#{file[:name]}", uploader: PersonalFileUploader)

    snippet.update_attribute(:description, "Description with #{markdown}'; select * from users;") unless file[:skip_description_update]
    create(:note_on_personal_snippet, noteable: snippet, note: "with #{markdown}") if file[:in_note]
  end

  def model_file_path(file)
    snippet = file[:snippet]
    secret = "secret#{file[:snippet].id}"

    File.join('personal_snippet', snippet.id.to_s, secret, file[:name])
  end
end
