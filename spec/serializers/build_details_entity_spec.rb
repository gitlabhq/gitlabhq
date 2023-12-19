# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildDetailsEntity do
  include ProjectForksHelper

  it 'inherits from Ci::JobEntity' do
    expect(described_class).to be < Ci::JobEntity
  end

  describe '#as_json' do
    let(:project) { create(:project, :repository) }
    let(:user) { project.first_owner }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, :failed, pipeline: pipeline) }
    let(:request) { double('request', project: project) }

    let(:entity) do
      described_class.new(build, request: request, current_user: user, project: project)
    end

    subject { entity.as_json }

    before do
      allow(request).to receive(:current_user).and_return(user)
    end

    it 'contains the needed key value pairs' do
      expect(subject).to include(:coverage, :erased_at, :finished_at, :duration)
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
          forked_project.add_developer(user)
        end

        let(:merge_request) do
          create(:merge_request, source_project: forked_project, target_project: project, source_branch: build.ref)
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

    context 'when the build has failed' do
      let(:build) { create(:ci_build, :created) }

      before do
        build.drop!(:unmet_prerequisites)
      end

      it { is_expected.to include(failure_reason: 'unmet_prerequisites') }
      it { is_expected.to include(callout_message: CommitStatusPresenter.callout_failure_messages[:unmet_prerequisites]) }
    end

    context 'when the build has failed due to a missing dependency' do
      let(:message) { subject[:callout_message] }

      context 'when the dependency is in the same pipeline' do
        let!(:test1) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test1', stage_idx: 0) }
        let!(:test2) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test2', stage_idx: 1) }
        let!(:build) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 2, options: { dependencies: %w[test1 test2] }) }

        before do
          build.pipeline.unlocked!
          build.drop!(:missing_dependency_failure)
        end

        it { is_expected.to include(failure_reason: 'missing_dependency_failure') }

        it 'includes the failing dependencies in the callout message' do
          expect(message).to include('test1')
          expect(message).to include('test2')
        end

        it 'includes message for list of invalid dependencies' do
          expect(message).to include('could not retrieve the needed artifacts:')
        end
      end

      context 'when dependency is not found' do
        let!(:build) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 2, options: { dependencies: %w[test1 test2] }) }

        before do
          build.pipeline.unlocked!
          build.drop!(:missing_dependency_failure)
        end

        it { is_expected.to include(failure_reason: 'missing_dependency_failure') }

        it 'excludes the failing dependencies in the callout message' do
          expect(message).not_to include('test1')
          expect(message).not_to include('test2')
        end

        it 'includes the correct punctuation in the message' do
          expect(message).to include('could not retrieve the needed artifacts.')
        end
      end

      context 'when dependency contains invalid dependency names' do
        invalid_name = 'XSS<a href=# data-disable-with="<img src=x onerror=alert(document.domain)>">'
        let!(:test1) { create(:ci_build, :success, :expired, pipeline: pipeline, name: invalid_name, stage_idx: 0) }
        let!(:build) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 1, options: { dependencies: [invalid_name] }) }

        before do
          build.pipeline.unlocked!
          build.drop!(:missing_dependency_failure)
        end

        it { is_expected.to include(failure_reason: 'missing_dependency_failure') }

        it 'escapes the invalid dependency names' do
          escaped_name = html_escape(invalid_name)
          expect(message).to include(escaped_name)
        end
      end
    end

    context 'when a build has environment with latest deployment' do
      let(:build) do
        create(:ci_build, :running, environment: environment.name, pipeline: pipeline)
      end

      let(:environment) do
        create(:environment, project: project, name: 'staging', state: :available)
      end

      before do
        create(:deployment, :success, environment: environment, project: project)

        allow(request).to receive(:project).and_return(project)
      end

      it 'does not serialize latest deployment commit and associated builds' do
        response = subject.with_indifferent_access

        response.dig(:deployment_status, :environment, :last_deployment).tap do |deployment|
          expect(deployment).not_to include(:commit, :manual_actions, :scheduled_actions)
        end
      end
    end

    context 'when the build has reports' do
      let!(:report) { create(:ci_job_artifact, :codequality, job: build) }

      it 'exposes the report artifacts' do
        expect(subject[:reports].count).to eq(1)
        expect(subject[:reports].first[:file_type]).to eq('codequality')
      end
    end

    context 'when the build has no archive type artifacts' do
      let!(:report) { create(:ci_job_artifact, :codequality, job: build) }

      it 'does not expose any artifact actions path' do
        expect(subject[:artifact].keys).not_to include(:download_path, :browse_path, :keep_path)
      end
    end

    context 'when the build has expired artifacts' do
      let!(:build) { create(:ci_build, :artifacts, pipeline: pipeline, artifacts_expire_at: 7.days.ago) }

      context 'when pipeline is unlocked' do
        before do
          build.pipeline.unlocked!
        end

        it 'artifact locked is false' do
          expect(subject.dig(:artifact, :locked)).to eq(false)
        end

        it 'does not expose any artifact actions path' do
          expect(subject[:artifact].keys).not_to include(:download_path, :browse_path, :keep_path)
        end
      end

      context 'when the pipeline is artifacts_locked' do
        before do
          build.pipeline.artifacts_locked!
        end

        it 'artifact locked is true' do
          expect(subject.dig(:artifact, :locked)).to eq(true)
        end

        it 'exposes download, browse and keep artifact actions path' do
          expect(subject[:artifact].keys).to include(:download_path, :browse_path, :keep_path)
        end
      end
    end

    context 'when the build has archive type artifacts' do
      let!(:build) { create(:ci_build, :artifacts, pipeline: pipeline, artifacts_expire_at: 7.days.from_now) }
      let!(:report) { create(:ci_job_artifact, :codequality, job: build) }

      it 'exposes artifact details' do
        expect(subject[:artifact].keys).to include(:download_path, :browse_path, :keep_path, :expire_at, :expired, :locked)
      end
    end

    context 'when the project is public and the user is a guest' do
      let(:project) { create(:project, :repository, :public) }
      let(:user) { create(:project_member, :guest, project: project).user }

      context 'when the build has public archive type artifacts' do
        let(:build) { create(:ci_build, :artifacts) }

        it 'exposes public artifact details' do
          expect(subject[:artifact].keys).to include(:download_path, :browse_path, :locked)
        end
      end

      context 'when the build has non public archive type artifacts' do
        let(:build) { create(:ci_build, :private_artifacts, :with_private_artifacts_config, pipeline: pipeline) }

        it 'does not expose non public artifacts' do
          expect(subject.keys).not_to include(:artifact)
        end
      end
    end

    context 'when the build has annotations' do
      let!(:build) { create(:ci_build) }
      let!(:annotation) { create(:ci_job_annotation, job: build, name: 'external_links', data: [{ external_link: { label: 'URL', url: 'https://example.com/' } }]) }

      it 'exposes job URLs' do
        expect(subject[:annotations].count).to eq(1)
        expect(subject[:annotations].first[:name]).to eq('external_links')
        expect(subject[:annotations].first[:data]).to include(a_hash_including(
          'external_link' => a_hash_including(
            'label' => 'URL',
            'url' => 'https://example.com/'
          )
        ))
      end
    end
  end
end
