require 'spec_helper'

module Ci
  describe ImageForBuildService do
    let(:service) { ImageForBuildService.new }
    let(:project) { FactoryGirl.create(:ci_project) }
    let(:gl_project) { FactoryGirl.create(:empty_project, gitlab_ci_project: project) }
    let(:commit) { FactoryGirl.create(:ci_commit, gl_project: gl_project, ref: 'master') }
    let(:build) { FactoryGirl.create(:ci_build, commit: commit) }

    describe :execute do
      before { build }

      context 'branch name' do
        before { build.run! }
        let(:image) { service.execute(project, ref: 'master') }

        it { expect(image).to be_kind_of(OpenStruct) }
        it { expect(image.path.to_s).to include('public/ci/build-running.svg') }
        it { expect(image.name).to eq('build-running.svg') }
      end

      context 'unknown branch name' do
        let(:image) { service.execute(project, ref: 'feature') }

        it { expect(image).to be_kind_of(OpenStruct) }
        it { expect(image.path.to_s).to include('public/ci/build-unknown.svg') }
        it { expect(image.name).to eq('build-unknown.svg') }
      end

      context 'commit sha' do
        before { build.run! }
        let(:image) { service.execute(project, sha: build.sha) }

        it { expect(image).to be_kind_of(OpenStruct) }
        it { expect(image.path.to_s).to include('public/ci/build-running.svg') }
        it { expect(image.name).to eq('build-running.svg') }
      end

      context 'unknown commit sha' do
        let(:image) { service.execute(project, sha: '0000000') }

        it { expect(image).to be_kind_of(OpenStruct) }
        it { expect(image.path.to_s).to include('public/ci/build-unknown.svg') }
        it { expect(image.name).to eq('build-unknown.svg') }
      end
    end
  end
end
