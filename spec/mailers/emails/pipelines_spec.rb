# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Pipelines do
  include EmailSpec::Matchers

  let_it_be(:project) { create(:project, :repository) }

  shared_examples_for 'correct pipeline information' do
    it 'has a correct information' do
      expect(subject)
          .to have_subject "#{status} pipeline for #{pipeline.source_ref} | " \
                           "#{project.name} | " \
                           "#{pipeline.short_sha}".to_s

      expect(subject).to have_body_text pipeline.source_ref
      expect(subject).to have_body_text status_text
    end

    context 'when pipeline on master branch has a merge request' do
      let(:pipeline) { create(:ci_pipeline, ref: 'master', sha: sha, project: project) }

      let!(:merge_request) do
        create(:merge_request, source_branch: 'master', target_branch: 'feature',
          source_project: project, target_project: project)
      end

      it 'has correct information that there is no merge request link' do
        expect(subject)
            .to have_subject "#{status} pipeline for #{pipeline.source_ref} | " \
                             "#{project.name} | " \
                             "#{pipeline.short_sha}".to_s

        expect(subject).to have_body_text pipeline.source_ref
        expect(subject).to have_body_text status_text
      end
    end

    context 'when pipeline for merge requests' do
      let(:pipeline) { merge_request.all_pipelines.first }

      let(:merge_request) do
        create(:merge_request, :with_detached_merge_request_pipeline,
          source_project: project,
          target_project: project)
      end

      it 'has correct information that there is a merge request link' do
        expect(subject)
          .to have_subject "#{status} pipeline for #{pipeline.source_ref} | " \
                           "#{project.name} | " \
                           "#{pipeline.short_sha}".to_s

        expect(subject).to have_body_text merge_request.to_reference
        expect(subject).to have_body_text pipeline.source_ref
        expect(subject).not_to have_body_text pipeline.ref
      end
    end

    context 'when branch pipeline is set to a merge request as a head pipeline' do
      let(:pipeline) do
        create(:ci_pipeline, project: project, ref: ref, sha: sha,
          merge_requests_as_head_pipeline: [merge_request])
      end

      let(:merge_request) do
        create(:merge_request, source_project: project, target_project: project)
      end

      it 'has correct information that there is a merge request link' do
        expect(subject)
          .to have_subject "#{status} pipeline for #{pipeline.source_ref} | " \
                           "#{project.name} | " \
                           "#{pipeline.short_sha}".to_s

        expect(subject).to have_body_text merge_request.to_reference
        expect(subject).to have_body_text pipeline.source_ref
      end
    end
  end

  describe '#pipeline_success_email' do
    subject { Notify.pipeline_success_email(pipeline, pipeline.user.try(:email)) }

    let(:pipeline) { create(:ci_pipeline, project: project, ref: ref, sha: sha) }
    let(:ref) { 'master' }
    let(:sha) { project.commit(ref).sha }

    it_behaves_like 'correct pipeline information' do
      let(:status) { 'Successful' }
      let(:status_text) { "Pipeline ##{pipeline.id} has passed!" }
    end
  end

  describe '#pipeline_failed_email' do
    subject { Notify.pipeline_failed_email(pipeline, pipeline.user.try(:email)) }

    let(:pipeline) { create(:ci_pipeline, project: project, ref: ref, sha: sha) }
    let(:ref) { 'master' }
    let(:sha) { project.commit(ref).sha }

    it_behaves_like 'correct pipeline information' do
      let(:status) { 'Failed' }
      let(:status_text) { "Pipeline ##{pipeline.id} has failed!" }
    end
  end

  describe '#pipeline_fixed_email' do
    subject { Notify.pipeline_fixed_email(pipeline, pipeline.user.try(:email)) }

    let(:pipeline) { create(:ci_pipeline, project: project, ref: ref, sha: sha) }
    let(:ref) { 'master' }
    let(:sha) { project.commit(ref).sha }

    it_behaves_like 'correct pipeline information' do
      let(:status) { 'Fixed' }
      let(:status_text) { "Pipeline has been fixed and ##{pipeline.id} has passed!" }
    end
  end
end
