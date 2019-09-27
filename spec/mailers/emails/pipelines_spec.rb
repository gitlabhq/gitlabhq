# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

describe Emails::Pipelines do
  include EmailSpec::Matchers

  set(:project) { create(:project, :repository) }

  shared_examples_for 'correct pipeline information' do
    it 'has a correct information' do
      expect(subject)
          .to have_subject "#{project.name} | Pipeline ##{pipeline.id} has " \
                           "#{status} for #{pipeline.source_ref} | " \
                           "#{pipeline.short_sha}".to_s

      expect(subject).to have_body_text pipeline.source_ref
      expect(subject).to have_body_text status_text
    end

    context 'when pipeline for merge requests' do
      let(:pipeline) { merge_request.all_pipelines.first }

      let(:merge_request) do
        create(:merge_request, :with_detached_merge_request_pipeline,
          source_project: project,
          target_project: project)
      end

      it 'has a correct information with merge request link' do
        expect(subject)
          .to have_subject "#{project.name} | Pipeline ##{pipeline.id} has " \
                           "#{status} for #{pipeline.source_ref} | " \
                           "#{pipeline.short_sha} in !#{merge_request.iid}".to_s

        expect(subject).to have_body_text merge_request.to_reference
        expect(subject).to have_body_text pipeline.source_ref
        expect(subject).not_to have_body_text pipeline.ref
      end
    end
  end

  describe '#pipeline_success_email' do
    subject { Notify.pipeline_success_email(pipeline, pipeline.user.try(:email)) }

    let(:pipeline) { create(:ci_pipeline, project: project, ref: ref, sha: sha) }
    let(:ref) { 'master' }
    let(:sha) { project.commit(ref).sha }

    it_behaves_like 'correct pipeline information' do
      let(:status) { 'succeeded' }
      let(:status_text) { 'Your pipeline has passed.' }
    end
  end

  describe '#pipeline_failed_email' do
    subject { Notify.pipeline_failed_email(pipeline, pipeline.user.try(:email)) }

    let(:pipeline) { create(:ci_pipeline, project: project, ref: ref, sha: sha) }
    let(:ref) { 'master' }
    let(:sha) { project.commit(ref).sha }

    it_behaves_like 'correct pipeline information' do
      let(:status) { 'failed' }
      let(:status_text) { 'Your pipeline has failed.' }
    end
  end
end
