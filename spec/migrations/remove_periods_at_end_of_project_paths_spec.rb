require 'spec_helper'
require Rails.root.join('db', 'migrate', '20171101160108_remove_periods_at_end_of_project_paths.rb')

describe RemovePeriodsAtEndOfProjectPaths, :migration do
  let!(:path) { 'foo' }
  let!(:namespace) { create(:namespace) }
  let!(:valid_project) { create(:project, namespace: namespace, path: path) }

  shared_examples 'invalid project path cleanup' do
    before do
      allow_any_instance_of(Project).to receive(:rename_repo).and_return(true)
    end

    context 'when there is no project collision' do
      it 'cleans up the project path' do
        project = build(:project, path: path_was)
        project.save!(validate: false)

        migrate!

        expect(project.reload.path).to eq(path)
      end
    end

    context 'when there is project collision' do
      it 'cleans up the project path with a number in front to avoid collision' do
        project = build(:project, namespace: namespace, path: path_was)
        project.save!(validate: false)

        migrate!

        expect(project.reload.path).to eq("#{path}0")
      end
    end
  end

  describe 'when path starts with -' do
    it_behaves_like 'invalid project path cleanup' do
      let!(:path_was) { "-#{path}" }
    end
  end

  describe 'when path ends with .' do
    it_behaves_like 'invalid project path cleanup' do
      let!(:path_was) { "#{path}." }
    end
  end

  describe 'when path ends with .git' do
    it_behaves_like 'invalid project path cleanup' do
      let!(:path_was) { "#{path}.git" }
    end
  end

  describe 'when path ends with .atom' do
    it_behaves_like 'invalid project path cleanup' do
      let!(:path_was) { "#{path}.atom" }
    end
  end

  describe 'when path ends with .atom.git' do
    it_behaves_like 'invalid project path cleanup' do
      let!(:path_was) { "#{path}.atom.git" }
    end
  end

  describe 'when path starts with - and ends with .atom.git' do
    it_behaves_like 'invalid project path cleanup' do
      let!(:path_was) { "-#{path}.atom.git" }
    end
  end

  describe 'when project path fails to update' do
    it 'raises StandardError' do
      project = build(:project, path: 'foo.git')
      project.save!(validate: false)

      allow_any_instance_of(Project).to receive(:save).and_return(false)

      expect { migrate! }.to raise_error(StandardError)
      expect(project.reload.path).to eq('foo.git')
    end
  end

  describe 'when repo fails to be renamed' do
    it 'raises StandardError' do
      project = build(:project, path: 'foo.git')
      project.save!(validate: false)

      allow_any_instance_of(Project).to receive(:rename_repo).and_raise(StandardError)

      expect { migrate! }.to raise_error(StandardError)
      expect(project.reload.path).to eq('foo.git')
    end
  end
end
