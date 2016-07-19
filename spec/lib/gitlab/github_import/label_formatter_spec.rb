require 'spec_helper'

describe Gitlab::GithubImport::LabelFormatter, lib: true do
  describe '#attributes' do
    it 'returns formatted attributes' do
      project = create(:project)
      raw = double(name: 'improvements', color: 'e6e6e6')

      formatter = described_class.new(project, raw)

      expect(formatter.attributes).to eq({
        project: project,
        title: 'improvements',
        color: '#e6e6e6'
      })
    end
  end
end
