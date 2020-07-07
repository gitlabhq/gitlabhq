# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupConcurrentSchemaChange do
  describe '#perform' do
    it 'new column does not exist' do
      expect(subject).to receive(:column_exists?).with(:issues, :closed_at_timestamp).and_return(false)
      expect(subject).not_to receive(:column_exists?).with(:issues, :closed_at)
      expect(subject).not_to receive(:define_model_for)

      expect(subject.perform(:issues, :closed_at, :closed_at_timestamp)).to be_nil
    end

    it 'old column does not exist' do
      expect(subject).to receive(:column_exists?).with(:issues, :closed_at_timestamp).and_return(true)
      expect(subject).to receive(:column_exists?).with(:issues, :closed_at).and_return(false)
      expect(subject).not_to receive(:define_model_for)

      expect(subject.perform(:issues, :closed_at, :closed_at_timestamp)).to be_nil
    end

    it 'has both old and new columns' do
      expect(subject).to receive(:column_exists?).twice.and_return(true)

      expect { subject.perform('issues', :closed_at, :created_at) }.to raise_error(NotImplementedError)
    end
  end
end
