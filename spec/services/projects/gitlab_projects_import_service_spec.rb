require 'spec_helper'

describe Projects::GitlabProjectsImportService do
  set(:namespace) { create(:namespace) }
  let(:file) { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }
  subject { described_class.new(namespace.owner, { namespace_id: namespace.id, path: path, file: file }) }

  describe '#execute' do
    context 'with an invalid path' do
      let(:path) { '/invalid-path/' }

      it 'returns an invalid project' do
        project = subject.execute

        expect(project).not_to be_persisted
        expect(project).not_to be_valid
      end
    end

    context 'with a valid path' do
      let(:path) { 'test-path' }

      it 'creates a project' do
        project = subject.execute

        expect(project).to be_persisted
        expect(project).to be_valid
      end
    end
  end
end
