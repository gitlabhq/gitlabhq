require 'spec_helper'

describe Gitlab::Import::Action::ImportLabels, lib: true do
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

  subject(:action) { described_class.new(project, client) }

  describe '#execute' do
    it { expect { subject.execute }.to change(Label, :count).by(1) }
  end
end
