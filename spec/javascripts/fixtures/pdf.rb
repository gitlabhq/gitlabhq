require 'spec_helper'

describe 'PDF file', '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'pdf-project') }

  before(:all) do
    clean_frontend_fixtures('blob/pdf/')
  end

  it 'blob/pdf/test.pdf' do |example|
    blob = project.repository.blob_at('e774ebd33', 'files/pdf/test.pdf')

    store_frontend_fixture(blob.data.force_encoding("utf-8"), example.description)
  end
end
