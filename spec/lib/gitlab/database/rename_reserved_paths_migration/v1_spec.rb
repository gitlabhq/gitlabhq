require 'spec_helper'

shared_examples 'renames child namespaces' do |type|
  it 'renames namespaces' do
    rename_namespaces = double
    expect(described_class::RenameNamespaces)
      .to receive(:new).with(['first-path', 'second-path'], subject)
           .and_return(rename_namespaces)
    expect(rename_namespaces).to receive(:rename_namespaces)
                                   .with(type: :child)

    subject.rename_wildcard_paths(['first-path', 'second-path'])
  end
end

describe Gitlab::Database::RenameReservedPathsMigration::V1, :delete do
  let(:subject) { FakeRenameReservedPathMigrationV1.new }

  before do
    allow(subject).to receive(:say)
  end

  describe '#rename_child_paths' do
    it_behaves_like 'renames child namespaces'
  end

  describe '#rename_wildcard_paths' do
    it_behaves_like 'renames child namespaces'

    it 'should rename projects' do
      rename_projects = double
      expect(described_class::RenameProjects)
        .to receive(:new).with(['the-path'], subject)
             .and_return(rename_projects)

      expect(rename_projects).to receive(:rename_projects)

      subject.rename_wildcard_paths(['the-path'])
    end
  end

  describe '#rename_root_paths' do
    it 'should rename namespaces' do
      rename_namespaces = double
      expect(described_class::RenameNamespaces)
        .to receive(:new).with(['the-path'], subject)
             .and_return(rename_namespaces)
      expect(rename_namespaces).to receive(:rename_namespaces)
                           .with(type: :top_level)

      subject.rename_root_paths('the-path')
    end
  end

  describe '#revert_renames' do
    it 'renames namespaces' do
      rename_namespaces = double
      expect(described_class::RenameNamespaces)
        .to receive(:new).with([], subject)
              .and_return(rename_namespaces)
      expect(rename_namespaces).to receive(:revert_renames)

      subject.revert_renames
    end

    it 'renames projects' do
      rename_projects = double
      expect(described_class::RenameProjects)
        .to receive(:new).with([], subject)
              .and_return(rename_projects)
      expect(rename_projects).to receive(:revert_renames)

      subject.revert_renames
    end
  end
end
