require 'spec_helper'
require 'composer'
require 'digest/crc32'

describe Gitlab::Composer::Package::Loader::ProjectLoader do
  let(:project) { create(:project) }

  before do
    @loader = Gitlab::Composer::Package::Loader::ProjectLoader.new
    @project = project
    @branch = project.repository.find_branch('master')
    @config = {
      'name' => 'group/project'
    }
  end

  describe '#load' do

    context 'with private project' do

      before do
        project.visibility_level = Gitlab::VisibilityLevel::PRIVATE
        project.save!
      end

      it 'succeeds' do
        package = @loader.load(@project, @branch, @config)
        expect(package.name).to eq('group/project')
        expect(package.pretty_version).to eq('dev-master')
        expect(package.version).to eq('9999999-dev')
        expect(package.type).to eq('library')
        expect(package.source_url).to eq(@project.url_to_repo)
        expect(package.source_type).to eq('git')
        expect(package.source_reference).to eq(@branch.target)
        expect(package.dist_url).to eq(nil)
        expect(package.dist_type).to eq(nil)
        expect(package.dist_reference).to eq(nil)
      end
    end

    context 'with public project' do

      before do
        project.visibility_level = Gitlab::VisibilityLevel::PUBLIC
        project.save!
      end

      it 'succeeds' do
        package = @loader.load(@project, @branch, @config)
        expect(package.name).to eq('group/project')
        expect(package.pretty_version).to eq('dev-master')
        expect(package.version).to eq('9999999-dev')
        expect(package.type).to eq('library')
        expect(package.source_url).to eq(@project.url_to_repo)
        expect(package.source_type).to eq('git')
        expect(package.source_reference).to eq(@branch.target)
        expect(package.dist_url).to eq([@project.web_url, 'repository', 'archive.zip?ref=' + @branch.name].join('/'))
        expect(package.dist_type).to eq('zip')
        expect(package.dist_reference).to eq(@branch.target)
      end
    end

  end

  it '#load fails on unamed' do
    expect { @loader.load(@project, @branch, {}) }.to raise_error(::Composer::UnexpectedValueError)
  end

end
