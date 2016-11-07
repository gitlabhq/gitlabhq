require 'rails_helper'

describe 'shared/_file_highlight.html.haml' do
  let(:file) { 'shared/file_highlight.html.haml' }

  context 'for csv blobs' do
    it 'renders a CSV partial' do
      blob = spy(csv?: true, data: nil)
      stub_template 'shared/_csv.html.haml' => 'CSV file'

      render file, blob: blob

      expect(rendered).to match('CSV file')
    end
  end

  context 'for other blobs' do
    it 'highlights the blob' do
      blob = instance_double(
        'Blob',
        data: 'data',
        path: 'path',
        no_highlighting?: true,
        id: 'id',
        csv?: false
      )
      repo = double

      expect(view).to receive(:highlight)
        .with('path', 'data', repository: repo, plain: true)

      render file, blob: blob, repository: repo
    end
  end
end
