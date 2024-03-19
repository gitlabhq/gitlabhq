# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Tasks::Database, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let(:options) { Backup::Options.new }

  subject(:task) { described_class.new(progress: progress, options: options) }

  describe '#pre_restore_warning' do
    context 'when force is false' do
      let(:options) { Backup::Options.new(force: false) }

      it 'returns a warning message' do
        expect(task.pre_restore_warning).to start_with('Be sure to stop Puma, Sidekiq, and any other process')
      end
    end

    context 'when force_is true' do
      let(:options) { Backup::Options.new(force: true) }

      it 'returns nil' do
        expect(task.pre_restore_warning).to be_nil
      end
    end
  end

  describe '#post_restore_warning' do
    context 'when restore finished with errors' do
      it 'returns a warning message' do
        mocked_target = instance_double(Backup::Targets::Database, errors: ['some errors'])
        allow(task).to receive(:target).and_return(mocked_target)

        expect(task.post_restore_warning).to start_with('There were errors in restoring the schema.')
      end
    end

    context 'when restore finished without any error' do
      it 'returns nil' do
        expect(task.post_restore_warning).to be_nil
      end
    end
  end
end
