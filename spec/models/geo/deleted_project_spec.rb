require 'spec_helper'

RSpec.describe Geo::DeletedProject, type: :model do
  subject { described_class.new(id: 1, name: 'sample', full_path: 'root/sample', repository_storage: nil) }

  it { expect(subject).to be_kind_of(Project) }

  describe '#full_path' do
    it 'returns the initialized value' do
      expect(subject.full_path).to eq 'root/sample'
    end
  end

  describe '#path_with_namespace' do
    it 'is an alias for full_path' do
      full_path = described_class.instance_method(:full_path)
      path_with_namespace = described_class.instance_method(:path_with_namespace)

      expect(path_with_namespace).to eq(full_path)
    end
  end

  describe '#repository' do
    it 'returns a valid repository' do
      expect(subject.repository).to be_kind_of(Repository)
      expect(subject.repository.path_with_namespace).to eq('root/sample')
    end
  end
end
