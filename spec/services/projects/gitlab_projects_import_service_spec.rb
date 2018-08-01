require 'spec_helper'

describe Projects::GitlabProjectsImportService do
  set(:namespace) { create(:namespace) }
  let(:path) { 'test-path' }
  let(:file) { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }
  let(:overwrite) { false }
  let(:import_params) { { namespace_id: namespace.id, path: path, file: file, overwrite: overwrite } }

  subject { described_class.new(namespace.owner, import_params) }

  describe '#execute' do
    it_behaves_like 'gitlab projects import validations'
  end
end
