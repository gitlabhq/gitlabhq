require 'spec_helper'

describe Gitlab::Import::Github::Mapper::Label, lib: true do
  let(:project) { create(:empty_project) }
  let(:client)  { double(labels: response) }

  let(:response) do
    [
      double(
        url: 'https://api.github.com/repos/octocat/Hello-World/labels/bug',
        name: 'Bug',
        color: 'f29513'
      )
    ]
  end

  subject(:mapper) { described_class.new(project, client) }

  describe '#each' do
    it 'yields successively with Label' do
      expect { |block| mapper.each(&block) }.to yield_successive_args(Label)
    end

    it 'matches the Label attributes' do
      mapper.each do |label|
        expect(label).to have_attributes(project: project, name: 'Bug', color: '#f29513')
      end
    end
  end
end
