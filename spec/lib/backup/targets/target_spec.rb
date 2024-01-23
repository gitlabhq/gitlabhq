# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Targets::Target, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let(:backup_options) { build(:backup_options) }

  subject(:target) { described_class.new(progress, options: backup_options) }

  describe '#options' do
    it 'has an accessor for Backup::Options' do
      expect(target.options).to be_a(Backup::Options)
    end
  end

  describe '#dump' do
    it 'must be implemented by the subclass' do
      expect { target.dump('some/path', 'backup_id') }.to raise_error(NotImplementedError)
    end
  end

  describe '#restore' do
    it 'must be implemented by the subclass' do
      expect { target.restore('some/path', 'backup_id') }.to raise_error(NotImplementedError)
    end
  end

  describe '#pre_restore_warning' do
    it { respond_to :pre_restore_warning }
  end

  describe '#pos_restore_warning' do
    it { respond_to :pos_restore_warning }
  end
end
