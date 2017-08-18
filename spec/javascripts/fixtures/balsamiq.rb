require 'spec_helper'

describe 'Balsamiq file', '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'balsamiq-project') }

  before(:all) do
    clean_frontend_fixtures('blob/balsamiq/')
  end

  it 'blob/balsamiq/test.bmpr' do |example|
    blob = project.repository.blob_at('b89b56d79', 'files/images/balsamiq.bmpr')

    store_frontend_fixture(blob.data.force_encoding('utf-8'), example.description)
  end
end
