# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Tasks::Task, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let(:options) { create(:backup_options) }

  subject(:task) { described_class.new(progress: progress, options: options) }

  context 'with unimplemented methods' do
    describe '.id' do
      it 'raises an error' do
        expect { described_class.id }.to raise_error(NotImplementedError)
      end
    end

    describe '#id' do
      it 'raises an error' do
        expect { task.id }.to raise_error(NotImplementedError)
      end
    end

    describe '#human_name' do
      it 'raises an error' do
        expect { task.human_name }.to raise_error(NotImplementedError)
      end
    end

    describe '#destination_path' do
      it 'raises an error' do
        expect { task.destination_path }.to raise_error(NotImplementedError)
      end
    end

    describe '#target' do
      it 'raises an error' do
        expect { task.send(:target) }.to raise_error(NotImplementedError)
      end
    end
  end
end
