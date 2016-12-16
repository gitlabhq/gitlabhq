require 'spec_helper'

describe Mattermost::Command do
  describe '.create' do
    let(:new_command) do
      JSON.parse(File.read(Rails.root.join('spec/fixtures/', 'mattermost_new_command.json')))
    end

    it 'gets the teams' do
      allow(described_class).to receive(:post_command).and_return(new_command)

      token = described_class.create('abc', url: 'http://trigger.url/trigger', icon_url: 'http://myicon.com/icon.png')

      expect(token).to eq('pzajm5hfbtni3r49ujpt8betpc')
    end
  end
end
