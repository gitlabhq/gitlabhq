# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Backup::Task do
  let(:progress) { StringIO.new }

  subject { described_class.new(progress) }

  describe '#dump' do
    it 'must be implemented by the subclass' do
      expect { subject.dump('some/path', 'backup_id') }.to raise_error(NotImplementedError)
    end
  end

  describe '#restore' do
    it 'must be implemented by the subclass' do
      expect { subject.restore('some/path') }.to raise_error(NotImplementedError)
    end
  end
end
