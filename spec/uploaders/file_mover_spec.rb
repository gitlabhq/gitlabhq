require 'spec_helper'

describe FileMover do
  let(:filename) { 'banana_sample.gif' }
  let(:file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', filename)) }
  let(:temp_file_path) { File.join('uploads/-/system/temp', 'secret55', filename) }

  let(:temp_description) do
    "test ![banana_sample](/#{temp_file_path}) "\
    "same ![banana_sample](/#{temp_file_path}) "
  end
  let(:file_path) { File.join('uploads/-/system/personal_snippet', snippet.id.to_s, 'secret55', filename) }
  let(:snippet) { create(:personal_snippet, description: temp_description) }

  subject { described_class.new(file_path, snippet).execute }

  describe '#execute' do
    before do
      expect(FileUtils).to receive(:mkdir_p).with(a_string_including(File.dirname(file_path)))
      expect(FileUtils).to receive(:move).with(a_string_including(temp_file_path), a_string_including(file_path))
      allow_any_instance_of(CarrierWave::SanitizedFile).to receive(:exists?).and_return(true)
      allow_any_instance_of(CarrierWave::SanitizedFile).to receive(:size).and_return(10)
    end

    context 'when move and field update successful' do
      it 'updates the description correctly' do
        subject

        expect(snippet.reload.description)
          .to eq(
            "test ![banana_sample](/uploads/-/system/personal_snippet/#{snippet.id}/secret55/banana_sample.gif) "\
            "same ![banana_sample](/uploads/-/system/personal_snippet/#{snippet.id}/secret55/banana_sample.gif) "
          )
      end

      it 'creates a new update record' do
        expect { subject }.to change { Upload.count }.by(1)
      end

      it 'schedules a background migration' do
        expect_any_instance_of(PersonalFileUploader).to receive(:schedule_background_upload).once

        subject
      end
    end

    context 'when update_markdown fails' do
      before do
        expect(FileUtils).to receive(:move).with(a_string_including(file_path), a_string_including(temp_file_path))
      end

      subject { described_class.new(file_path, snippet, :non_existing_field).execute }

      it 'does not update the description' do
        subject

        expect(snippet.reload.description)
          .to eq(
            "test ![banana_sample](/uploads/-/system/temp/secret55/banana_sample.gif) "\
            "same ![banana_sample](/uploads/-/system/temp/secret55/banana_sample.gif) "
          )
      end

      it 'does not create a new update record' do
        expect { subject }.not_to change { Upload.count }
      end
    end
  end
end
