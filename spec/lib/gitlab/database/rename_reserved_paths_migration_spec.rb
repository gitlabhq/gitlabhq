require 'spec_helper'

describe Gitlab::Database::RenameReservedPathsMigration do
  let(:subject) { FakeRenameReservedPathMigration.new }

  before do
    allow(subject).to receive(:say)
  end

  describe '#rename_wildcard_paths' do
    it 'should rename namespaces' do
      rename_namespaces = double
      expect(Gitlab::Database::RenameReservedPathsMigration::RenameNamespaces).
        to receive(:new).with(['first-path', 'second-path'], subject).
             and_return(rename_namespaces)
      expect(rename_namespaces).to receive(:rename_namespaces).
                           with(type: :wildcard)

      subject.rename_wildcard_paths(['first-path', 'second-path'])
    end

    it 'should rename projects' do
      rename_projects = double
      expect(Gitlab::Database::RenameReservedPathsMigration::RenameProjects).
        to receive(:new).with(['the-path'], subject).
             and_return(rename_projects)

      expect(rename_projects).to receive(:rename_projects)

      subject.rename_wildcard_paths(['the-path'])
    end
  end

  describe '#rename_root_paths' do
    it 'should rename namespaces' do
      rename_namespaces = double
      expect(Gitlab::Database::RenameReservedPathsMigration::RenameNamespaces).
        to receive(:new).with(['the-path'], subject).
             and_return(rename_namespaces)
      expect(rename_namespaces).to receive(:rename_namespaces).
                           with(type: :top_level)

      subject.rename_root_paths('the-path')
    end
  end
end
