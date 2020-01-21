# frozen_string_literal: true

require 'spec_helper'

describe UploadTypeCheck do
  include_context 'uploader with type check'

  def upload_fixture(filename)
    fixture_file_upload(File.join('spec', 'fixtures', filename))
  end

  describe '#check_content_matches_extension! callback using file upload' do
    context 'when extension matches contents' do
      it 'not raise error on upload' do
        expect { uploader.cache!(upload_fixture('banana_sample.gif')) }.not_to raise_error
      end
    end

    context 'when extension does not match contents' do
      it 'raise error' do
        expect { uploader.cache!(upload_fixture('not_a_png.png')) }.to raise_error(CarrierWave::IntegrityError)
      end
    end
  end

  describe '#check_content_matches_extension! callback using stubs' do
    include_context 'stubbed MimeMagic mime type detection'

    context 'when no extension and with ambiguous/text content' do
      let(:magic_mime) { '' }
      let(:ext_mime) { '' }

      it_behaves_like 'upload passes content type check'
    end

    context 'when no extension and with non-text content' do
      let(:magic_mime) { 'image/gif' }
      let(:ext_mime) { '' }

      it_behaves_like 'upload fails content type check'
    end

    # Most text files will exhibit this behaviour.
    context 'when ambiguous content with text extension' do
      let(:magic_mime) { '' }
      let(:ext_mime) { 'text/plain' }

      it_behaves_like 'upload passes content type check'
    end

    context 'when text content with text extension' do
      let(:magic_mime) { 'text/plain' }
      let(:ext_mime) { 'text/plain' }

      it_behaves_like 'upload passes content type check'
    end

    context 'when ambiguous content with non-text extension' do
      let(:magic_mime) { '' }
      let(:ext_mime) { 'application/zip' }

      it_behaves_like 'upload fails content type check'
    end

    # These are the types when uploading a .dmg
    context 'when content and extension do not match' do
      let(:magic_mime) { 'application/x-bzip' }
      let(:ext_mime) { 'application/x-apple-diskimage' }

      it_behaves_like 'upload fails content type check'
    end
  end

  describe '#check_content_matches_extension! mime_type filtering' do
    context 'without mime types' do
      let(:mime_types) { nil }

      it_behaves_like 'type checked uploads', %w[doc_sample.txt rails_sample.jpg]
    end

    context 'with mime types string' do
      let(:mime_types) { 'text/plain' }

      it_behaves_like 'type checked uploads', %w[doc_sample.txt]
      it_behaves_like 'skipped type checked uploads', %w[dk.png]
    end

    context 'with mime types regex' do
      let(:mime_types) { [/image\/(gif|png)/] }

      it_behaves_like 'type checked uploads', %w[banana_sample.gif dk.png]
      it_behaves_like 'skipped type checked uploads', %w[doc_sample.txt]
    end

    context 'with mime types array' do
      let(:mime_types) { ['text/plain', /image\/png/] }

      it_behaves_like 'type checked uploads', %w[doc_sample.txt dk.png]
      it_behaves_like 'skipped type checked uploads', %w[audio_sample.wav]
    end
  end

  describe '#check_content_matches_extension! extensions filtering' do
    context 'without extensions' do
      let(:extensions) { nil }

      it_behaves_like 'type checked uploads', %w[doc_sample.txt dk.png]
    end

    context 'with extensions string' do
      let(:extensions) { 'txt' }

      it_behaves_like 'type checked uploads', %w[doc_sample.txt]
      it_behaves_like 'skipped type checked uploads', %w[rails_sample.jpg]
    end

    context 'with extensions array of strings' do
      let(:extensions) { %w[txt png] }

      it_behaves_like 'type checked uploads', %w[doc_sample.txt dk.png]
      it_behaves_like 'skipped type checked uploads', %w[audio_sample.wav]
    end
  end
end
