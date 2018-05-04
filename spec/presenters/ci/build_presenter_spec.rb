require 'spec_helper'

describe Ci::BuildPresenter do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  subject(:presenter) do
    described_class.new(build)
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#initialize' do
    it 'takes a build and optional params' do
      expect { presenter }.not_to raise_error
    end

    it 'exposes build' do
      expect(presenter.build).to eq(build)
    end

    it 'forwards missing methods to build' do
      expect(presenter.ref).to eq('master')
    end
  end

  describe '#erased_by_user?' do
    it 'takes a build and optional params' do
      expect(presenter).not_to be_erased_by_user
    end
  end

  describe '#erased_by_name' do
    context 'when build is not erased' do
      before do
        expect(presenter).to receive(:erased_by_user?).and_return(false)
      end

      it 'returns nil' do
        expect(presenter.erased_by_name).to be_nil
      end
    end

    context 'when build is erased' do
      before do
        expect(presenter).to receive(:erased_by_user?).and_return(true)
        expect(build).to receive(:erased_by)
          .and_return(double(:user, name: 'John Doe'))
      end

      it 'returns the name of the eraser' do
        expect(presenter.erased_by_name).to eq('John Doe')
      end
    end
  end

  describe '#status_title' do
    context 'when build is auto-canceled' do
      before do
        expect(build).to receive(:auto_canceled?).and_return(true)
        expect(build).to receive(:auto_canceled_by_id).and_return(1)
      end

      it 'shows that the build is auto-canceled' do
        status_title = presenter.status_title

        expect(status_title).to include('auto-canceled')
        expect(status_title).to include('Pipeline #1')
      end
    end

    context 'when build failed' do
      let(:build) { create(:ci_build, :failed, pipeline: pipeline) }

      it 'returns the reason of failure' do
        status_title = presenter.status_title

        expect(status_title).to eq('Failed <br> (unknown failure)')
      end
    end

    context 'when build has failed && retried' do
      let(:build) { create(:ci_build, :failed, :retried, pipeline: pipeline) }

      it 'does not include retried title' do
        status_title = presenter.status_title

        expect(status_title).not_to include('(retried)')
        expect(status_title).to eq('Failed <br> (unknown failure)')
      end
    end

    context 'when build has failed and is allowed to' do
      let(:build) { create(:ci_build, :failed, :allowed_to_fail, pipeline: pipeline) }

      it 'returns the reason of failure' do
        status_title = presenter.status_title

        expect(status_title).to eq('Failed <br> (unknown failure)')
      end
    end

    context 'For any other build' do
      let(:build) { create(:ci_build, :success, pipeline: pipeline) }

      it 'returns the status' do
        tooltip_description = presenter.status_title

        expect(tooltip_description).to eq('Success')
      end
    end
  end

  describe 'quack like a Ci::Build permission-wise' do
    context 'user is not allowed' do
      let(:project) { create(:project, public_builds: false) }

      it 'returns false' do
        expect(presenter.can?(nil, :read_build)).to be_falsy
      end
    end

    context 'user is allowed' do
      let(:project) { create(:project, :public) }

      it 'returns true' do
        expect(presenter.can?(nil, :read_build)).to be_truthy
      end
    end
  end

  describe '#trigger_variables' do
    let(:build) { create(:ci_build, pipeline: pipeline, trigger_request: trigger_request) }
    let(:trigger) { create(:ci_trigger, project: project) }
    let(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline, trigger: trigger) }

    context 'when variable is stored in ci_pipeline_variables' do
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline) }

      context 'when pipeline is triggered by trigger API' do
        it 'returns variables' do
          expect(presenter.trigger_variables).to eq([pipeline_variable.to_runner_variable])
        end
      end

      context 'when pipeline is not triggered by trigger API' do
        let(:build) { create(:ci_build, pipeline: pipeline) }

        it 'does not return variables' do
          expect(presenter.trigger_variables).to eq([])
        end
      end
    end

    context 'when variable is stored in ci_trigger_requests.variables' do
      before do
        trigger_request.update_attribute(:variables, { 'TRIGGER_KEY_1' => 'TRIGGER_VALUE_1' } )
      end

      it 'returns variables' do
        expect(presenter.trigger_variables).to eq(trigger_request.user_variables)
      end
    end
  end

  describe '#tooltip_message' do
    context 'When build has failed' do
      let(:build) { create(:ci_build, :script_failure, pipeline: pipeline) }

      it 'returns the reason of failure' do
        tooltip = subject.tooltip_message

        expect(tooltip).to eq("#{build.name} - failed <br> (script failure)")
      end
    end

    context 'When build has failed and retried' do
      let(:build) { create(:ci_build, :script_failure, :retried, pipeline: pipeline) }

      it 'should include the reason of failure and the retried title' do
        tooltip = subject.tooltip_message

        expect(tooltip).to eq("#{build.name} - failed <br> (script failure) (retried)")
      end
    end

    context 'When build has failed and is allowed to' do
      let(:build) { create(:ci_build, :script_failure, :allowed_to_fail, pipeline: pipeline) }

      it 'should include the reason of failure' do
        tooltip = subject.tooltip_message

        expect(tooltip).to eq("#{build.name} - failed <br> (script failure) (allowed to fail)")
      end
    end

    context 'For any other build (no retried)' do
      let(:build) { create(:ci_build, :success, pipeline: pipeline) }

      it 'should include build name and status' do
        tooltip = subject.tooltip_message

        expect(tooltip).to eq("#{build.name} - passed")
      end
    end

    context 'For any other build (retried)' do
      let(:build) { create(:ci_build, :success, :retried, pipeline: pipeline) }

      it 'should include build name and status' do
        tooltip = subject.tooltip_message

        expect(tooltip).to eq("#{build.name} - passed (retried)")
      end
    end
  end

  describe '#callout_failure_message' do
    let(:build) { create(:ci_build, :failed, :script_failure) }

    it 'returns a verbose failure reason' do
      description = subject.callout_failure_message
      expect(description).to eq('There has been a script failure. Check the job log for more information')
    end
  end

  describe '#recoverable?' do
    let(:build) { create(:ci_build, :failed, :script_failure) }

    context 'when is a script or missing dependency failure' do
      let(:failure_reasons) { %w(script_failure missing_dependency_failure) }

      it 'should return false' do
        failure_reasons.each do |failure_reason|
          build.update_attribute(:failure_reason, failure_reason)
          expect(presenter.recoverable?).to be_falsy
        end
      end
    end

    context 'when is any other failure type' do
      let(:failure_reasons) { %w(unknown_failure api_failure stuck_or_timeout_failure runner_system_failure) }

      it 'should return true' do
        failure_reasons.each do |failure_reason|
          build.update_attribute(:failure_reason, failure_reason)
          expect(presenter.recoverable?).to be_truthy
        end
      end
    end
  end
end
