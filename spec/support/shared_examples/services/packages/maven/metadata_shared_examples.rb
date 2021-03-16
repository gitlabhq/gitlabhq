# frozen_string_literal: true

RSpec.shared_examples 'handling metadata content pointing to a file for the create xml service' do
  context 'with metadata content pointing to a file' do
    let(:service) { described_class.new(metadata_content: file, package: package) }
    let(:file) do
      Tempfile.new('metadata').tap do |file|
        if file_contents
          file.write(file_contents)
          file.flush
          file.rewind
        end
      end
    end

    after do
      file.close
      file.unlink
    end

    context 'with valid content' do
      let(:file_contents) { metadata_xml }

      it 'returns no changes' do
        expect(subject).to be_success
        expect(subject.payload).to eq(changes_exist: false, empty_versions: false)
      end
    end

    context 'with invalid content' do
      let(:file_contents) { '<meta></metadata>' }

      it_behaves_like 'returning an error service response', message: 'metadata_content is invalid'
    end

    context 'with no content' do
      let(:file_contents) { nil }

      it_behaves_like 'returning an error service response', message: 'metadata_content is invalid'
    end
  end
end

RSpec.shared_examples 'handling invalid parameters for create xml service' do
  context 'with no package' do
    let(:metadata_xml) { '' }
    let(:package) { nil }

    it_behaves_like 'returning an error service response', message: 'package not set'
  end

  context 'with no metadata content' do
    let(:metadata_xml) { nil }

    it_behaves_like 'returning an error service response', message: 'metadata_content not set'
  end
end
