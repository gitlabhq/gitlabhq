require 'spec_helper'

describe ContainerRegistry::Path do
  subject { described_class.new(path) }

  describe '#components' do
    let(:path) { 'path/to/some/project' }

    it 'splits components by a forward slash' do
      expect(subject.components).to eq %w[path to some project]
    end
  end

  describe '#nodes' do
    context 'when repository path is valid' do
      let(:path) { 'path/to/some/project' }

      it 'return all project path like node in reverse order' do
        expect(subject.nodes).to eq %w[path/to/some/project
                                       path/to/some
                                       path/to]
      end
    end

    context 'when repository path is invalid' do
      let(:path) { '' }

      it 'rasises en error' do
        expect { subject.nodes }
          .to raise_error described_class::InvalidRegistryPathError
      end
    end
  end

  describe '#to_s' do
    context 'when path does not have uppercase characters' do
      let(:path) { 'some/image' }

      it 'return a string with a repository path' do
        expect(subject.to_s).to eq 'some/image'
      end
    end

    context 'when path has uppercase characters' do
      let(:path) { 'SoMe/ImAgE' }

      it 'return a string with a repository path' do
        expect(subject.to_s).to eq 'some/image'
      end
    end
  end

  describe '#valid?' do
    context 'when path has less than two components' do
      let(:path) { 'something/' }

      it { is_expected.not_to be_valid }
    end

    context 'when path has more than allowed number of components' do
      let(:path) { 'a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/r/s/t/u/w/y/z' }

      it { is_expected.not_to be_valid }
    end

    context 'when path has invalid characters' do
      let(:path) { 'some\path' }

      it { is_expected.not_to be_valid }
    end

    context 'when path has two or more components' do
      let(:path) { 'some/path' }

      it { is_expected.to be_valid }
    end

    context 'when path is related to multi-level image' do
      let(:path) { 'some/path/my/image' }

      it { is_expected.to be_valid }
    end

    context 'when path contains uppercase letters' do
      let(:path) { 'Some/Registry' }

      it { is_expected.to be_valid }
    end
  end

  describe '#has_repository?' do
    context 'when project exists' do
      let(:project) { create(:empty_project) }
      let(:path) { "#{project.full_path}/my/image" }

      context 'when path already has matching repository' do
        before do
          create(:container_repository, project: project, name: 'my/image')
        end

        it { is_expected.to have_repository }
        it { is_expected.to have_project }
      end

      context 'when path does not have matching repository' do
        it { is_expected.not_to have_repository }
        it { is_expected.to have_project }
      end
    end

    context 'when project does not exist' do
      let(:path) { 'some/project/my/image' }

      it { is_expected.not_to have_repository }
      it { is_expected.not_to have_project }
    end
  end

  describe '#repository_project' do
    let(:group) { create(:group, path: 'some_group') }

    context 'when project for given path exists' do
      let(:path) { 'some_group/some_project' }

      before do
        create(:empty_project, group: group, name: 'some_project')
        create(:empty_project, name: 'some_project')
      end

      it 'returns a correct project' do
        expect(subject.repository_project.group).to eq group
      end
    end

    context 'when project for given path does not exist' do
      let(:path) { 'not/matching' }

      it 'returns nil' do
        expect(subject.repository_project).to be_nil
      end
    end

    context 'when matching multi-level path' do
      let(:project) do
        create(:empty_project, group: group, name: 'some_project')
      end

      context 'when using the zero-level path' do
        let(:path) { project.full_path }

        it 'supports zero-level path' do
          expect(subject.repository_project).to eq project
        end
      end

      context 'when using first-level path' do
        let(:path) { "#{project.full_path}/repository" }

        it 'supports first-level path' do
          expect(subject.repository_project).to eq project
        end
      end

      context 'when using second-level path' do
        let(:path) { "#{project.full_path}/repository/name" }

        it 'supports second-level path' do
          expect(subject.repository_project).to eq project
        end
      end

      context 'when using too deep nesting in the path' do
        let(:path) { "#{project.full_path}/repository/name/invalid" }

        it 'does not support three-levels of nesting' do
          expect(subject.repository_project).to be_nil
        end
      end
    end
  end

  describe '#repository_name' do
    context 'when project does not exist' do
      let(:path) { 'some/name' }

      it 'returns nil' do
        expect(subject.repository_name).to be_nil
      end
    end

    context 'when project exists' do
      let(:group) { create(:group, path: 'some_group') }

      let(:project) do
        create(:empty_project, group: group, name: 'some_project')
      end

      before do
        allow(path).to receive(:repository_project)
          .and_return(project)
      end

      context 'when project path equal repository path' do
        let(:path) { 'some_group/some_project' }

        it 'returns an empty string' do
          expect(subject.repository_name).to eq ''
        end
      end

      context 'when repository path has one additional level' do
        let(:path) { 'some_group/some_project/repository' }

        it 'returns a correct repository name' do
          expect(subject.repository_name).to eq 'repository'
        end
      end

      context 'when repository path has two additional levels' do
        let(:path) { 'some_group/some_project/repository/image' }

        it 'returns a correct repository name' do
          expect(subject.repository_name).to eq 'repository/image'
        end
      end
    end
  end
end
