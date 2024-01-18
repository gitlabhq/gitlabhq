# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Task, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let(:backup_options) { build(:backup_options) }

  subject { described_class.new(progress, options: backup_options) }

  describe '#dump' do
    it 'must be implemented by the subclass' do
      expect { subject.dump('some/path', 'backup_id') }.to raise_error(NotImplementedError)
    end
  end

  describe '#restore' do
    it 'must be implemented by the subclass' do
      expect { subject.restore('some/path', 'backup_id') }.to raise_error(NotImplementedError)
    end
  end
end
