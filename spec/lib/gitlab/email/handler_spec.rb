require 'spec_helper'

describe Gitlab::Email::Handler do
  describe '.for' do
    it 'picks issue handler if there is not merge request prefix' do
      expect(described_class.for('email', 'project+key')).to be_an_instance_of(Gitlab::Email::Handler::CreateIssueHandler)
    end

    it 'picks merge request handler if there is merge request key' do
      expect(described_class.for('email', 'project+merge-request+key')).to be_an_instance_of(Gitlab::Email::Handler::CreateMergeRequestHandler)
    end

    it 'returns nil if no handler is found' do
      expect(described_class.for('email', '')).to be_nil
    end
  end
end
