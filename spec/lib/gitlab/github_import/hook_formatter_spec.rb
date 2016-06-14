require 'spec_helper'

describe Gitlab::GithubImport::HookFormatter, lib: true do
  describe '#id' do
    it 'returns raw id' do
      raw = double(id: 100000)
      formatter = described_class.new(raw)
      expect(formatter.id).to eq 100000
    end
  end

  describe '#name' do
    it 'returns raw id' do
      raw = double(name: 'web')
      formatter = described_class.new(raw)
      expect(formatter.name).to eq 'web'
    end
  end

  describe '#config' do
    it 'returns raw config.attrs' do
      raw = double(config: double(attrs: { url: 'http://something.com/webhook' }))
      formatter = described_class.new(raw)
      expect(formatter.config).to eq({ url: 'http://something.com/webhook' })
    end
  end

  describe '#valid?' do
    it 'returns true when events contains the wildcard event' do
      raw = double(events: ['*', 'commit_comment'], active: true)
      formatter = described_class.new(raw)
      expect(formatter.valid?).to eq true
    end

    it 'returns true when events contains the create event' do
      raw = double(events: ['create', 'commit_comment'], active: true)
      formatter = described_class.new(raw)
      expect(formatter.valid?).to eq true
    end

    it 'returns true when events contains delete event' do
      raw = double(events: ['delete', 'commit_comment'], active: true)
      formatter = described_class.new(raw)
      expect(formatter.valid?).to eq true
    end

    it 'returns true when events contains pull_request event' do
      raw = double(events: ['pull_request', 'commit_comment'], active: true)
      formatter = described_class.new(raw)
      expect(formatter.valid?).to eq true
    end

    it 'returns false when events does not contains branch related events' do
      raw = double(events: ['member', 'commit_comment'], active: true)
      formatter = described_class.new(raw)
      expect(formatter.valid?).to eq false
    end

    it 'returns false when hook is not active' do
      raw = double(events: ['pull_request', 'commit_comment'], active: false)
      formatter = described_class.new(raw)
      expect(formatter.valid?).to eq false
    end
  end
end
