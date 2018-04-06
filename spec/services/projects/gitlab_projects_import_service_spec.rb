require 'spec_helper'

describe Projects::GitlabProjectsImportService do
  set(:namespace) { create(:namespace) }
  let(:path) { 'test-path' }
  let(:file) { fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain') }
  let(:import_params) { { namespace_id: namespace.id, path: path, file: file } }
  subject { described_class.new(namespace.owner, import_params) }

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
      it 'creates a project' do
        project = subject.execute

        expect(project).to be_persisted
        expect(project).to be_valid
      end
    end

    context 'override params' do
      it 'stores them as import data when passed' do
        project = described_class
                    .new(namespace.owner, import_params, description: 'Hello')
                    .execute

        expect(project.import_data.data['override_params']['description']).to eq('Hello')
      end
    end
  end
end
