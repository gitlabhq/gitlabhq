require 'spec_helper'

describe ContainerRegistry::Path do
  let(:path) { described_class.new(name) }

  describe '#components' do
    context 'when repository path is valid' do
      let(:name) { 'path/to/some/project' }

      it 'return all project-like components in reverse order' do
        expect(path.components).to eq %w[path/to/some/project
                                         path/to/some
                                         path/to]
      end
    end

    context 'when repository path is invalid' do
      let(:name) { '' }

      it 'rasises en error' do
        expect { path.components }
          .to raise_error described_class::InvalidRegistryPathError
      end
    end
  end

  describe '#valid?' do
    context 'when path has less than two components' do
      let(:name) { 'something/' }

      it 'is not valid' do
        expect(path).not_to be_valid
      end
    end

    context 'when path has more than allowed number of components' do
      let(:name) { 'a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/r/s/t/u/w/y/z' }

      it 'is not valid' do
        expect(path).not_to be_valid
      end
    end

    context 'when path has two or more components' do
      let(:name) { 'some/path' }

      it 'is valid' do
        expect(path).to be_valid
      end
    end
  end

  describe '#repository_project' do
    let(:group) { create(:group, path: 'some_group') }

    context 'when project for given path exists' do
      let(:name) { 'some_group/some_project' }

      before do
        create(:empty_project, group: group, name: 'some_project')
        create(:empty_project, name: 'some_project')
      end

      it 'returns a correct project' do
        expect(path.repository_project.group).to eq group
      end
    end

    context 'when project for given path does not exist' do
      let(:name) { 'not/matching' }

      it 'returns nil' do
        expect(path.repository_project).to be_nil
      end
    end

    context 'when matching multi-level path' do
      let(:project) do
        create(:empty_project, group: group, name: 'some_project')
      end

      context 'when using the zero-level path' do
        let(:name) { project.full_path }

        it 'supports zero-level path' do
          expect(path.repository_project).to eq project
        end
      end

      context 'when using first-level path' do
        let(:name) { "#{project.full_path}/repository" }

        it 'supports first-level path' do
          expect(path.repository_project).to eq project
        end
      end

      context 'when using second-level path' do
        let(:name) { "#{project.full_path}/repository/name" }

        it 'supports second-level path' do
          expect(path.repository_project).to eq project
        end
      end

      context 'when using too deep nesting in the path' do
        let(:name) { "#{project.full_path}/repository/name/invalid" }

        it 'does not support three-levels of nesting' do
          expect(path.repository_project).to be_nil
        end
      end
    end
  end

  describe '#repository_name' do
    pending 'returns a correct name'
  end
end
