# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GitlabProjectsImportService do
  let_it_be(:namespace) { create(:namespace) }

  let(:path) { 'test-path' }
  let(:file) { fixture_file_upload('spec/fixtures/project_export.tar.gz') }
  let(:overwrite) { false }
  let(:import_params) { { namespace_id: namespace.id, path: path, file: file, overwrite: overwrite } }

  subject { described_class.new(namespace.owner, import_params) }

  describe '#execute' do
    it_behaves_like 'gitlab projects import validations'
  end
end
