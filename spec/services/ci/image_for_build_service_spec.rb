require 'spec_helper'

module Ci
  describe ImageForBuildService, services: true do
    let(:service) { ImageForBuildService.new }
    let(:project) { FactoryGirl.create(:empty_project) }
    let(:commit_sha) { '01234567890123456789' }
    let(:commit) { project.ensure_ci_commit(commit_sha) }
    let(:build) { FactoryGirl.create(:ci_build, commit: commit) }

    describe :execute do
      before { build }

      context 'branch name' do
        before { allow(project).to receive(:commit).and_return(OpenStruct.new(sha: commit_sha)) }
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
