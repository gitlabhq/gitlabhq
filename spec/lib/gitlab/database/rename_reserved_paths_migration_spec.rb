require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration do
  let(:subject) do
    ActiveRecord::Migration.new.extend(
      Gitlab::Database::RenameReservedPathsMigration
    )
  end

  describe '#rename_wildcard_paths' do
    it 'should rename namespaces' do
      expect(subject).to receive(:rename_namespaces).
                           with(['first-path', 'second-path'], type: :wildcard)

      subject.rename_wildcard_paths(['first-path', 'second-path'])
    end

    it 'should rename projects'
  end

  describe '#rename_root_paths' do
    it 'should rename namespaces' do
      expect(subject).to receive(:rename_namespaces).
                           with(['the-path'], type: :top_level)

      subject.rename_root_paths('the-path')
    end
  end
end
