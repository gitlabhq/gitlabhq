# frozen_string_literal: true

RSpec.shared_examples 'pipeline notification integration' do |integration_name|
  using RSpec::Parameterized::TableSyntax

  context 'when pipeline_status_change_notifications feature flag is enabled' do
    where(
      :ref_status_name, :pipeline_status,
      :notify_only_when_pipeline_status_changes, :notify_only_broken_pipelines,
      :triggered
    ) do
      [
        # notifications always sent
        [:broken,        'failed',  false, false, true],
        [:broken,        'failed',  true,  false, true],
        [:broken,        'failed',  false, true,  true],
        [:broken,        'failed',  true,  true,  true],
        # notifications not sent when notify_only_broken_pipelines is enabled
        [:fixed,         'success', false, false, true],
        [:fixed,         'success', true,  false, true],
        [:fixed,         'success', false, true,  false],
        [:fixed,         'success', true,  true,  false],
        # notifications sent unless notify_only_when_pipeline_status_changes is enabled
        [:still_failing, 'failed',  false, false, true],
        [:still_failing, 'failed',  true,  false, false],
        [:still_failing, 'failed',  false, true,  true],
        [:still_failing, 'failed',  true,  true,  false],
        # notifications not sent when notify_only_when_pipeline_status_changes or
        # notify_only_broken_pipelines is enabled
        [:success,       'success', false, false, true],
        [:success,       'success', true,  false, false],
        [:success,       'success', false, true,  false],
        [:success,       'success', true,  true,  false]
      ]
    end

    with_them do
      let(:ci_ref_status) { Ci::Ref.state_machines[:status].states[ref_status_name].value }
      let(:ci_ref)        { create(:ci_ref, status: ci_ref_status, project: project) }

      let(:pipeline) do
        create(
          :ci_pipeline,
          project: project,
          ci_ref: ci_ref,
          status: pipeline_status,
          sha: project.commit.sha,
          ref: project.default_branch
        )
      end

      before do
        stub_feature_flags(pipeline_status_change_notifications: true)

        subject.notify_only_when_pipeline_status_changes = notify_only_when_pipeline_status_changes
        subject.notify_only_broken_pipelines = notify_only_broken_pipelines
      end

      if params[:triggered]
        it_behaves_like "triggered #{integration_name} integration"
      else
        it_behaves_like "untriggered #{integration_name} integration"
      end
    end
  end

  context 'when pipeline_status_change_notifications feature flag is disabled' do
    where(
      :ref_status_name, :pipeline_status,
      :notify_only_when_pipeline_status_changes, :notify_only_broken_pipelines,
      :triggered
    ) do
      [
        # notifications always sent for failed pipelines regardless of notify_only_when_pipeline_status_changes
        [:broken,        'failed',  false, false, true],
        [:broken,        'failed',  true,  false, true],
        [:broken,        'failed',  false, true,  true],
        [:broken,        'failed',  true,  true,  true],
        [:still_failing, 'failed',  false, false, true],
        [:still_failing, 'failed',  true,  false, true],
        [:still_failing, 'failed',  false, true,  true],
        [:still_failing, 'failed',  true,  true,  true],
        # notifications not sent when notify_only_broken_pipelines is enabled,
        # regardless of notify_only_when_pipeline_status_changes
        [:fixed,         'success', false, false, true],
        [:fixed,         'success', true,  false, true],
        [:fixed,         'success', false, true,  false],
        [:fixed,         'success', true,  true,  false],
        [:success,       'success', false, false, true],
        [:success,       'success', true,  false, true],
        [:success,       'success', false, true,  false],
        [:success,       'success', true,  true,  false]
      ]
    end

    with_them do
      let(:ci_ref_status) { Ci::Ref.state_machines[:status].states[ref_status_name].value }
      let(:ci_ref)        { create(:ci_ref, status: ci_ref_status, project: project) }

      let(:pipeline) do
        create(
          :ci_pipeline,
          project: project,
          ci_ref: ci_ref,
          status: pipeline_status,
          sha: project.commit.sha,
          ref: project.default_branch
        )
      end

      before do
        stub_feature_flags(pipeline_status_change_notifications: false)

        subject.notify_only_when_pipeline_status_changes = notify_only_when_pipeline_status_changes
        subject.notify_only_broken_pipelines = notify_only_broken_pipelines
      end

      if params[:triggered]
        it_behaves_like "triggered #{integration_name} integration"
      else
        it_behaves_like "untriggered #{integration_name} integration"
      end
    end
  end
end
