require 'spec_helper'

describe Gitlab::GitlabImport::Importer do
  include ImportSpecHelper

  describe '#execute' do
    before do
      stub_omniauth_provider('gitlab')
      stub_request('issues', [
        {
          'id' => 2579857,
          'iid' => 3,
          'title' => 'Issue',
          'description' => 'Lorem ipsum',
          'state' => 'opened',
          'confidential' => true,
          'author' => {
            'id' => 283999,
            'name' => 'John Doe'
          }
        }
      ])
      stub_request('issues/2579857/notes', [])
    end

    it 'persists issues' do
      project = create(:project, import_source: 'asd/vim')
      project.build_import_data(credentials: { password: 'password' })

      subject = described_class.new(project)
      subject.execute

      expected_attributes = {
        iid: 3,
        title: 'Issue',
        description: "*Created by: John Doe*\n\nLorem ipsum",
        state: 'opened',
        confidential: true,
        author_id: project.creator_id
      }

      expect(project.issues.first).to have_attributes(expected_attributes)
    end

    def stub_request(path, body)
      url = "https://gitlab.com/api/v3/projects/asd%2Fvim/#{path}?page=1&per_page=100"

      WebMock.stub_request(:get, url)
        .to_return(
          headers: { 'Content-Type' => 'application/json' },
          body: body
        )
    end
  end
end
