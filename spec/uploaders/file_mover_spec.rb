require 'spec_helper'

describe FileMover do
  let(:filename) { 'banana_sample.gif' }
  let(:file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', filename)) }
  let(:temp_description) { 'test ![banana_sample](/uploads/temp/secret55/banana_sample.gif)' }
  let(:temp_file_path) { File.join('secret55', filename).to_s }
  let(:file_path) { File.join('uploads', 'personal_snippet', snippet.id.to_s, 'secret55', filename).to_s }

  let(:snippet) { create(:personal_snippet, description: temp_description) }

  subject { described_class.new(file_path, snippet).execute }

  describe '#execute' do
    it 'updates the description correctly' do
      expect(FileUtils).to receive(:mkdir_p).with(a_string_including(file_path))
      expect(FileUtils).to receive(:move).with(a_string_including(temp_file_path), a_string_including(file_path))

      subject

      expect(snippet.reload.description)
        .to eq("test ![banana_sample](/uploads/personal_snippet/#{snippet.id}/secret55/banana_sample.gif)")
    end
  end
end
