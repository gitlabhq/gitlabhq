# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FileMover do
  include FileMoverHelpers

  let(:user) { create(:user) }
  let(:filename) { 'banana_sample.gif' }
  let(:secret) { SecureRandom.hex }
  let(:temp_file_path) { File.join("uploads/-/system/user/#{user.id}", secret, filename) }

  let(:temp_description) do
    "test ![banana_sample](/#{temp_file_path}) "\
    "same ![banana_sample](/#{temp_file_path}) "
  end

  let(:file_path) { File.join('uploads/-/system/personal_snippet', snippet.id.to_s, secret, filename) }
  let(:snippet) { create(:personal_snippet, description: temp_description) }

  let(:tmp_uploader) do
    PersonalFileUploader.new(user, secret: secret)
  end

  let(:file) { fixture_file_upload('spec/fixtures/banana_sample.gif') }

  subject { described_class.new(temp_file_path, from_model: user, to_model: snippet).execute }

  describe '#execute' do
    let(:tmp_upload) { tmp_uploader.upload }

    before do
      tmp_uploader.store!(file)
    end

    context 'local storage' do
      before do
        allow(FileUtils).to receive(:mkdir_p).with(a_string_including(File.dirname(file_path)))
        allow(FileUtils).to receive(:move).with(a_string_including(temp_file_path), a_string_including(file_path))
        allow_any_instance_of(CarrierWave::SanitizedFile).to receive(:exists?).and_return(true)
        allow_any_instance_of(CarrierWave::SanitizedFile).to receive(:size).and_return(10)

        stub_file_mover(temp_file_path)
      end

      context 'when move and field update successful' do
        it 'updates the description correctly' do
          subject

          expect(snippet.reload.description)
            .to eq("test ![banana_sample](/uploads/-/system/personal_snippet/#{snippet.id}/#{secret}/banana_sample.gif) "\
                   "same ![banana_sample](/uploads/-/system/personal_snippet/#{snippet.id}/#{secret}/banana_sample.gif) ")
        end

        it 'updates existing upload record' do
          expect { subject }
            .to change { tmp_upload.reload.attributes.values_at('model_id', 'model_type') }
            .from([user.id, 'User']).to([snippet.id, 'Snippet'])
        end
      end

      context 'when update_markdown fails' do
        before do
          expect(FileUtils).to receive(:move).with(a_string_including(file_path), a_string_including(temp_file_path))
        end

        subject { described_class.new(file_path, :non_existing_field, from_model: user, to_model: snippet).execute }

        it 'does not update the description' do
          subject

          expect(snippet.reload.description)
            .to eq("test ![banana_sample](/uploads/-/system/user/#{user.id}/#{secret}/banana_sample.gif) "\
                   "same ![banana_sample](/uploads/-/system/user/#{user.id}/#{secret}/banana_sample.gif) ")
        end

        it 'does not change the upload record' do
          expect { subject }
            .not_to change { tmp_upload.reload.attributes.values_at('model_id', 'model_type') }
        end
      end
    end

    context 'when tmp uploader is not local storage' do
      before do
        stub_uploads_object_storage(uploader: PersonalFileUploader)
        allow_any_instance_of(PersonalFileUploader).to receive(:file_storage?) { false }
      end

      after do
        FileUtils.rm_f(File.join('personal_snippet', snippet.id.to_s, secret, filename))
      end

      context 'when move and field update successful' do
        it 'updates the description correctly' do
          subject

          expect(snippet.reload.description)
            .to eq("test ![banana_sample](/uploads/-/system/personal_snippet/#{snippet.id}/#{secret}/banana_sample.gif) "\
                   "same ![banana_sample](/uploads/-/system/personal_snippet/#{snippet.id}/#{secret}/banana_sample.gif) ")
        end

        it 'creates new target upload record an delete the old upload' do
          expect { subject }
            .to change { Upload.last.attributes.values_at('model_id', 'model_type') }
            .from([user.id, 'User']).to([snippet.id, 'Snippet'])

          expect(Upload.count).to eq(1)
        end
      end

      context 'when update_markdown fails' do
        subject { described_class.new(file_path, :non_existing_field, from_model: user, to_model: snippet).execute }

        it 'does not update the description' do
          subject

          expect(snippet.reload.description)
            .to eq("test ![banana_sample](/uploads/-/system/user/#{user.id}/#{secret}/banana_sample.gif) "\
                   "same ![banana_sample](/uploads/-/system/user/#{user.id}/#{secret}/banana_sample.gif) ")
        end

        it 'does not change the upload record' do
          expect { subject }
            .to change { Upload.last.attributes.values_at('model_id', 'model_type') }.from([user.id, 'User'])
        end
      end
    end
  end

  context 'security' do
    context 'when relative path is involved' do
      let(:temp_file_path) { File.join("uploads/-/system/user/#{user.id}", '..', 'another_subdir_of_temp') }

      it 'does not trigger move if path is outside designated directory' do
        expect(FileUtils).not_to receive(:move)
        expect { subject }.to raise_error(FileUploader::InvalidSecret)
      end
    end

    context 'when symlink is involved' do
      it 'does not trigger move if path is outside designated directory' do
        stub_file_mover(temp_file_path, stub_real_path: Pathname('/etc'))
        expect(FileUtils).not_to receive(:move)

        subject

        expect(snippet.reload.description).to eq(temp_description)
      end
    end
  end
end
