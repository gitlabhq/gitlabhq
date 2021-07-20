# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::CreateService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:tag_name) { project.repository.tag_names.first }
  let(:tag_sha) { project.repository.find_tag(tag_name).dereferenced_target.sha }
  let(:name) { 'Bionic Beaver' }
  let(:description) { 'Awesome release!' }
  let(:params) { { tag: tag_name, name: name, description: description, ref: ref } }
  let(:ref) { nil }
  let(:service) { described_class.new(project, user, params) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    shared_examples 'a successful release creation' do
      it 'creates a new release' do
        expected_job_count = MailScheduler::NotificationServiceWorker.jobs.size + 1

        expect_next_instance_of(Release) do |release|
          expect(release)
            .to receive(:execute_hooks)
            .with('create')
        end

        result = service.execute

        expect(project.releases.count).to eq(1)
        expect(result[:status]).to eq(:success)
        expect(result[:tag]).not_to be_nil
        expect(result[:release]).not_to be_nil
        expect(result[:release].description).to eq(description)
        expect(result[:release].name).to eq(name)
        expect(result[:release].author).to eq(user)
        expect(result[:release].sha).to eq(tag_sha)
        expect(MailScheduler::NotificationServiceWorker.jobs.size).to eq(expected_job_count)
      end
    end

    it_behaves_like 'a successful release creation'

    context 'when tag is protected and user does not have access to it' do
      let!(:protected_tag) { create(:protected_tag, :no_one_can_create, name: '*', project: project) }

      it 'track the error event' do
        stub_feature_flags(evalute_protected_tag_for_release_permissions: false)

        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          kind_of(described_class::ReleaseProtectedTagAccessError),
          project_id: project.id,
          user_id: user.id)

        service.execute
      end
    end

    context 'when the tag does not exist' do
      let(:tag_name) { 'non-exist-tag' }

      it 'raises an error' do
        result = service.execute

        expect(result[:status]).to eq(:error)
      end
    end

    context 'when ref is provided' do
      let(:ref) { 'master' }
      let(:tag_name) { 'foobar' }

      it_behaves_like 'a successful release creation'

      it 'creates a tag if the tag does not exist' do
        expect(project.repository.ref_exists?("refs/tags/#{tag_name}")).to be_falsey

        result = service.execute
        expect(result[:status]).to eq(:success)
        expect(result[:tag]).not_to be_nil
        expect(result[:release]).not_to be_nil
      end
    end

    context 'there already exists a release on a tag' do
      let!(:release) do
        create(:release, project: project, tag: tag_name, description: description)
      end

      it 'raises an error and does not update the release' do
        result = service.execute
        expect(result[:status]).to eq(:error)
        expect(project.releases.find_by(tag: tag_name).description).to eq(description)
      end
    end

    context 'when a passed-in milestone does not exist for this project' do
      it 'raises an error saying the milestone is inexistent' do
        inexistent_milestone_tag = 'v111.0'
        service = described_class.new(project, user, params.merge!({ milestones: [inexistent_milestone_tag] }))
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Milestone(s) not found: #{inexistent_milestone_tag}")
      end
    end
  end

  describe '#find_or_build_release' do
    it 'does not save the built release' do
      service.find_or_build_release

      expect(project.releases.count).to eq(0)
    end

    context 'when existing milestone is passed in' do
      let(:title) { 'v1.0' }
      let(:milestone) { create(:milestone, :active, project: project, title: title) }
      let(:params_with_milestone) { params.merge!({ milestones: [title] }) }
      let(:service) { described_class.new(milestone.project, user, params_with_milestone) }

      it 'creates a release and ties this milestone to it' do
        result = service.execute

        expect(project.releases.count).to eq(1)
        expect(result[:status]).to eq(:success)

        release = project.releases.last

        expect(release.milestones).to match_array([milestone])
      end

      context 'when another release was previously created with that same milestone linked' do
        it 'also creates another release tied to that same milestone' do
          other_release = create(:release, milestones: [milestone], project: project, tag: 'v1.0')
          service.execute
          release = project.releases.last

          expect(release.milestones).to match_array([milestone])
          expect(other_release.milestones).to match_array([milestone])
          expect(release.id).not_to eq(other_release.id)
        end
      end
    end

    context 'when multiple existing milestone titles are passed in' do
      let(:title_1) { 'v1.0' }
      let(:title_2) { 'v1.0-rc' }
      let!(:milestone_1) { create(:milestone, :active, project: project, title: title_1) }
      let!(:milestone_2) { create(:milestone, :active, project: project, title: title_2) }
      let!(:params_with_milestones) { params.merge!({ milestones: [title_1, title_2] }) }

      it 'creates a release and ties it to these milestones' do
        described_class.new(project, user, params_with_milestones).execute
        release = project.releases.last

        expect(release.milestones.map(&:title)).to include(title_1, title_2)
      end
    end

    context 'when multiple miletone titles are passed in but one of them does not exist' do
      let(:title) { 'v1.0' }
      let(:inexistent_title) { 'v111.0' }
      let!(:milestone) { create(:milestone, :active, project: project, title: title) }
      let!(:params_with_milestones) { params.merge!({ milestones: [title, inexistent_title] }) }
      let(:service) { described_class.new(milestone.project, user, params_with_milestones) }

      it 'raises an error' do
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Milestone(s) not found: #{inexistent_title}")
      end

      it 'does not create any release' do
        expect do
          service.execute
        end.not_to change(Release, :count)
      end
    end

    context 'no milestone association behavior' do
      let(:title_1) { 'v1.0' }
      let(:title_2) { 'v1.0-rc' }
      let!(:milestone_1) { create(:milestone, :active, project: project, title: title_1) }
      let!(:milestone_2) { create(:milestone, :active, project: project, title: title_2) }

      context 'when no milestones parameter is passed' do
        it 'creates a release without a milestone tied to it' do
          expect(service.param_for_milestone_titles_provided?).to be_falsey

          service.execute
          release = project.releases.last

          expect(release.milestones).to be_empty
        end

        it 'does not create any new MilestoneRelease object' do
          expect { service.execute }.not_to change { MilestoneRelease.count }
        end
      end

      context 'when an empty array is passed as the milestones parameter' do
        it 'creates a release without a milestone tied to it' do
          service = described_class.new(project, user, params.merge!({ milestones: [] }))
          service.execute
          release = project.releases.last

          expect(release.milestones).to be_empty
        end
      end

      context 'when nil is passed as the milestones parameter' do
        it 'creates a release without a milestone tied to it' do
          expect(service.param_for_milestone_titles_provided?).to be_falsey

          service = described_class.new(project, user, params.merge!({ milestones: nil }))
          service.execute
          release = project.releases.last

          expect(release.milestones).to be_empty
        end
      end
    end
  end

  context 'Evidence collection' do
    let(:sha) { project.repository.commit('master').sha }
    let(:params) do
      {
        name: 'New release',
        ref: 'master',
        tag: 'v0.1',
        description: 'Super nice release',
        released_at: released_at
      }.compact
    end

    let(:last_release) { project.releases.last }

    around do |example|
      freeze_time { example.run }
    end

    subject { service.execute }

    context 'historical release' do
      let(:released_at) { 3.weeks.ago }

      it 'does not execute CreateEvidenceWorker' do
        expect { subject }.not_to change(Releases::CreateEvidenceWorker.jobs, :size)
      end

      it 'does not create an Evidence object', :sidekiq_inline do
        expect { subject }.not_to change(Releases::Evidence, :count)
      end

      it 'is a historical release' do
        subject

        expect(last_release.historical_release?).to be_truthy
      end

      it 'is not an upcoming release' do
        subject

        expect(last_release.upcoming_release?).to be_falsy
      end
    end

    shared_examples 'uses the right pipeline for evidence' do
      it 'creates evidence without pipeline if it does not exist', :sidekiq_inline do
        expect_next_instance_of(Releases::CreateEvidenceService, anything, pipeline: nil) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect { subject }.to change(Releases::Evidence, :count).by(1)
      end

      it 'uses the last pipeline for evidence', :sidekiq_inline do
        create(:ci_empty_pipeline, sha: sha, project: project) # old pipeline
        pipeline = create(:ci_empty_pipeline, sha: sha, project: project)

        expect_next_instance_of(Releases::CreateEvidenceService, anything, pipeline: pipeline) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect { subject }.to change(Releases::Evidence, :count).by(1)
      end

      context 'when old evidence_pipeline is passed to service' do
        let!(:old_pipeline) { create(:ci_empty_pipeline, sha: sha, project: project) }
        let!(:new_pipeline) { create(:ci_empty_pipeline, sha: sha, project: project) }
        let(:params) do
          super().merge(
            evidence_pipeline: old_pipeline
          )
        end

        it 'uses the old pipeline for evidence', :sidekiq_inline do
          expect_next_instance_of(Releases::CreateEvidenceService, anything, pipeline: old_pipeline) do |service|
            expect(service).to receive(:execute).and_call_original
          end

          expect { subject }.to change(Releases::Evidence, :count).by(1)
        end
      end

      it 'pipeline is still being used for evidence if new pipeline is being created for tag', :sidekiq_inline do
        pipeline = create(:ci_empty_pipeline, sha: sha, project: project)

        expect(project.repository).to receive(:add_tag).and_wrap_original do |m, *args|
          create(:ci_empty_pipeline, sha: sha, project: project)
          m.call(*args)
        end

        expect_next_instance_of(Releases::CreateEvidenceService, anything, pipeline: pipeline) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect { subject }.to change(Releases::Evidence, :count).by(1)
      end

      it 'uses the last pipeline for evidence when tag is already created', :sidekiq_inline do
        Tags::CreateService.new(project, user).execute('v0.1', 'master', nil)

        expect(project.repository.find_tag('v0.1')).to be_present

        create(:ci_empty_pipeline, sha: sha, project: project) # old pipeline
        pipeline = create(:ci_empty_pipeline, sha: sha, project: project)

        expect_next_instance_of(Releases::CreateEvidenceService, anything, pipeline: pipeline) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect { subject }.to change(Releases::Evidence, :count).by(1)
      end
    end

    context 'immediate release' do
      let(:released_at) { nil }

      it 'sets `released_at` to the current dttm' do
        subject

        expect(last_release.updated_at).to be_like_time(Time.current)
      end

      it 'queues CreateEvidenceWorker' do
        expect { subject }.to change(Releases::CreateEvidenceWorker.jobs, :size).by(1)
      end

      it 'creates Evidence', :sidekiq_inline do
        expect { subject }.to change(Releases::Evidence, :count).by(1)
      end

      it 'is not a historical release' do
        subject

        expect(last_release.historical_release?).to be_falsy
      end

      it 'is not an upcoming release' do
        subject

        expect(last_release.upcoming_release?).to be_falsy
      end

      include_examples 'uses the right pipeline for evidence'
    end

    context 'upcoming release' do
      let(:released_at) { 1.day.from_now }

      it 'does not execute CreateEvidenceWorker' do
        expect { subject }.not_to change(Releases::CreateEvidenceWorker.jobs, :size)
      end

      it 'does not create an Evidence object', :sidekiq_inline do
        expect { subject }.not_to change(Releases::Evidence, :count)
      end

      it 'is not a historical release' do
        subject

        expect(last_release.historical_release?).to be_falsy
      end

      it 'is an upcoming release' do
        subject

        expect(last_release.upcoming_release?).to be_truthy
      end
    end
  end
end
