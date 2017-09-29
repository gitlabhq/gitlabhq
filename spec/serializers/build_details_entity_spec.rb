require 'spec_helper'

describe BuildDetailsEntity do
  include ProjectForksHelper

  set(:user) { create(:admin) }

  it 'inherits from JobEntity' do
    expect(described_class).to be < JobEntity
  end

  describe '#as_json' do
    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, :failed, pipeline: pipeline) }
    let(:request) { double('request') }

    let(:entity) do
      described_class.new(build, request: request,
                                 current_user: user,
                                 project: project)
    end

    subject { entity.as_json }

    before do
      allow(request).to receive(:current_user).and_return(user)
    end

    it 'contains the needed key value pairs' do
      expect(subject).to include(:coverage, :erased_at, :duration)
      expect(subject).to include(:runner, :pipeline)
      expect(subject).to include(:raw_path, :new_issue_path)
    end

    context 'when the user has access to issues and merge requests' do
      context 'when merge request orginates from the same project' do
        let(:merge_request) do
          create(:merge_request, source_project: project, source_branch: build.ref)
        end

        before do
          allow(build).to receive(:merge_request).and_return(merge_request)
        end

        it 'contains the needed key value pairs' do
          expect(subject).to include(:merge_request)
          expect(subject).to include(:new_issue_path)
        end

        it 'exposes correct details of the merge request' do
          expect(subject[:merge_request][:iid]).to eq merge_request.iid
        end

        it 'has a correct merge request path' do
          expect(subject[:merge_request][:path]).to include project.full_path
        end
      end

      context 'when merge request is from a fork' do
        let(:forked_project) { fork_project(project) }

        let(:pipeline) { create(:ci_pipeline, project: forked_project) }

        before do
          allow(build).to receive(:merge_request).and_return(merge_request)
        end

        let(:merge_request) do
          create(:merge_request, source_project: forked_project,
                                 target_project: project,
                                 source_branch: build.ref)
        end

        it 'contains the needed key value pairs' do
          expect(subject).to include(:merge_request)
          expect(subject).to include(:new_issue_path)
        end

        it 'exposes details of the merge request' do
          expect(subject[:merge_request][:iid]).to eq merge_request.iid
        end

        it 'has a merge request path to a target project' do
          expect(subject[:merge_request][:path])
            .to include project.full_path
        end
      end

      context 'when the build has not been erased' do
        let(:build) { create(:ci_build, :erasable, project: project) }

        it 'exposes a build erase path' do
          expect(subject).to include(:erase_path)
        end
      end

      context 'when the build has been erased' do
        let(:build) { create(:ci_build, :erased, project: project) }

        it 'exposes the user who erased the build' do
          expect(subject).to include(:erased_by)
        end
      end
    end

    context 'when the user can only read the build' do
      let(:user) { create(:user) }

      it "won't display the paths to issues and merge requests" do
        expect(subject['new_issue_path']).to be_nil
        expect(subject['merge_request_path']).to be_nil
      end
    end
  end
end
