# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPollWidgetEntity do
  include ProjectForksHelper
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project)  { create :project, :repository }
  let_it_be(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:user)     { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }
  let(:options) { {} }

  subject do
    described_class.new(resource, { request: request }.merge(options)).as_json
  end

  it 'has default_merge_commit_message_with_description' do
    expect(subject[:default_merge_commit_message_with_description])
      .to eq(resource.default_merge_commit_message(include_description: true))
  end

  it { is_expected.to include(ff_only_enabled: false) }
  it { is_expected.to include(ff_merge_possible: false) }
  it { is_expected.to include(retargeted: false) }

  describe 'new_blob_path' do
    context 'when user can push to project' do
      it 'returns path' do
        project.add_developer(user)

        expect(subject[:new_blob_path])
          .to eq("/#{resource.project.full_path}/-/new/#{resource.source_branch}")
      end
    end

    context 'when user cannot push to project' do
      it 'returns nil' do
        expect(subject[:new_blob_path]).to be_nil
      end
    end
  end

  describe 'auto merge' do
    before do
      project.add_maintainer(user)
    end

    context 'when auto merge is enabled' do
      let(:resource) { create(:merge_request, :merge_when_checks_pass) }

      it 'returns auto merge related information' do
        expect(subject[:auto_merge_strategy]).to eq('merge_when_checks_pass')
      end
    end

    context 'when auto merge is not enabled' do
      let(:resource) { create(:merge_request) }

      it 'returns auto merge related information' do
        expect(subject[:auto_merge_strategy]).to be_nil
      end
    end

    context 'when head pipeline is running' do
      before do
        create(:ci_pipeline, :running, project: project, ref: resource.source_branch, sha: resource.diff_head_sha)
        resource.update_head_pipeline
      end

      it 'returns available auto merge strategies' do
        expect(subject[:available_auto_merge_strategies]).to eq(%w[merge_when_checks_pass])
      end
    end

    describe 'squash defaults for projects' do
      where(:squash_option, :value, :default, :readonly) do
        'always'      | true  | true  | true
        'never'       | false | false | true
        'default_on'  | false | true  | false
        'default_off' | false | false | false
      end

      with_them do
        before do
          project.project_setting.update!(squash_option: squash_option)
        end

        it 'the key reflects the correct value' do
          expect(subject[:squash_on_merge]).to eq(value)
          expect(subject[:squash_enabled_by_default]).to eq(default)
          expect(subject[:squash_readonly]).to eq(readonly)
        end
      end
    end

    context 'when head pipeline is finished' do
      before do
        create(:ci_pipeline, :success, project: project, ref: resource.source_branch, sha: resource.diff_head_sha)
        resource.update_head_pipeline
      end

      it 'returns available auto merge strategies' do
        expect(subject[:available_auto_merge_strategies]).to be_empty
      end
    end
  end

  describe 'pipeline' do
    let!(:pipeline) { create(:ci_empty_pipeline, project: project, ref: resource.source_branch, sha: resource.source_branch_sha, head_pipeline_of: resource) }

    before do
      allow_any_instance_of(MergeRequestPresenter).to receive(:can?).and_call_original
      allow_any_instance_of(MergeRequestPresenter).to receive(:can?).with(user, :read_pipeline, anything).and_return(result)
    end

    context 'when user has access to pipelines' do
      let(:result) { true }

      context 'when is up to date' do
        let(:req) { double('request', current_user: user, project: project) }

        it 'does not return pipeline' do
          expect(subject[:pipeline]).to be_nil
        end

        it 'returns ci_status' do
          expect(subject[:ci_status]).to eq('pending')
        end
      end

      context 'when is not up to date' do
        it 'returns nil' do
          pipeline.update!(sha: "not up to date")

          expect(subject[:pipeline]).to eq(nil)
        end
      end
    end

    context 'when user does not have access to pipelines' do
      let(:result) { false }
      let(:req) { double('request', current_user: user, project: project) }

      it 'does not return ci_status' do
        expect(subject[:ci_status]).to eq(nil)
      end
    end
  end

  describe '#builds_with_coverage' do
    it 'serializes the builds with coverage' do
      allow(resource).to receive(:head_pipeline_builds_with_coverage).and_return(
        [
          double(name: 'rspec', coverage: 91.5),
          double(name: 'jest', coverage: 94.1)
        ])

      result = subject[:builds_with_coverage]

      expect(result).to eq(
        [
          { name: 'rspec', coverage: 91.5 },
          { name: 'jest', coverage: 94.1 }
        ])
    end
  end

  describe '#mergeable' do
    it 'shows whether a merge request is mergeable' do
      expect(subject[:mergeable]).to eq(true)
    end

    context 'when merge request is in checking state' do
      before do
        resource.mark_as_unchecked!
        resource.mark_as_checking!
      end

      it 'calculates mergeability and returns true' do
        expect(subject[:mergeable]).to eq(true)
      end
    end
  end

  describe '#jenkins_integration_active' do
    let_it_be_with_reload(:project_with_integration) { create :project, :repository }
    let_it_be_with_reload(:integration) { create(:jenkins_integration, push_events: true, project: project_with_integration) }
    let_it_be_with_reload(:resource) { create(:merge_request, source_project: project_with_integration, target_project: project_with_integration) }

    subject do
      described_class.new(resource, { request: request }.merge(options)).as_json
    end

    before do
      integration.update!(active: active)
    end

    context 'with active Jenkins integration' do
      let(:active) { true }

      it { expect(subject[:jenkins_integration_active]).to eq(true) }
    end

    context 'with inactive Jenkins integration' do
      let(:active) { false }

      it { expect(subject[:jenkins_integration_active]).to eq(false) }
    end
  end
end
