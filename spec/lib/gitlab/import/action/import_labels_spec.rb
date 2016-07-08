require 'spec_helper'

describe Gitlab::Import::Action::ImportLabels, lib: true do
  let(:project) { create(:empty_project) }
  let(:client)  { double(labels: response) }
  let(:result)  { double(errors: []) }

  let(:response) do
    [
      double(
        url: 'https://api.github.com/repos/octocat/Hello-World/labels/bug',
        name: 'Bug',
        color: 'f29513'
      ),
      double(
        url: 'https://api.github.com/repos/octocat/Hello-World/labels/bug',
        name: 'Bug',
        color: 'f29513'
      )
    ]
  end

  subject(:action) { described_class.new(project, client, result) }

  describe '#execute' do
    it 'persists labels' do
      expect { subject.execute }.to change(Label, :count).by(1)
    end

    it 'keeps track of errors' do
      result = subject.execute
      expect(result.errors).to eq ['Bug: Title has already been taken']
    end
  end
end
