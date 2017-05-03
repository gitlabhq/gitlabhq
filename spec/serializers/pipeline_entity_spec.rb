require 'spec_helper'

describe PipelineEntity do
  let(:user) { create(:user) }
  let(:request) { double('request') }

  before do
    allow(request).to receive(:user).and_return(user)
  end

  let(:entity) do
    described_class.represent(pipeline, request: request)
  end

  describe '#as_json' do
    subject { entity.as_json }

    context 'when pipeline is empty' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      it 'contains required fields' do
        expect(subject).to include :id, :user, :path
        expect(subject).to include :ref, :commit
        expect(subject).to include :updated_at, :created_at
      end

      it 'contains details' do
        expect(subject).to include :details
        expect(subject[:details])
          .to include :duration, :finished_at
        expect(subject[:details])
          .to include :stages, :artifacts, :manual_actions
        expect(subject[:details][:status]).to include :icon, :text, :label
      end

      it 'contains flags' do
        expect(subject).to include :flags
        expect(subject[:flags])
          .to include :latest, :triggered, :stuck,
                      :yaml_errors, :retryable, :cancelable
      end
    end

    context 'when pipeline is retryable' do
      let(:project) { create(:empty_project) }

      let(:pipeline) do
        create(:ci_pipeline, status: :success, project: project)
      end

      before do
        create(:ci_build, :failed, pipeline: pipeline)
      end

      context 'user has ability to retry pipeline' do
        before { project.team << [user, :developer] }

        it 'retryable flag is true' do
          expect(subject[:flags][:retryable]).to eq true
        end

        it 'contains retry path' do
          expect(subject[:retry_path]).to be_present
        end
      end

      context 'user does not have ability to retry pipeline' do
        it 'retryable flag is false' do
          expect(subject[:flags][:retryable]).to eq false
        end

        it 'does not contain retry path' do
          expect(subject).not_to have_key(:retry_path)
        end
      end
    end

    context 'when pipeline is cancelable' do
      let(:project) { create(:empty_project) }

      let(:pipeline) do
        create(:ci_pipeline, status: :running, project: project)
      end

      before do
        create(:ci_build, :pending, pipeline: pipeline)
      end

      context 'user has ability to cancel pipeline' do
        before { project.team << [user, :developer] }

        it 'cancelable flag is true' do
          expect(subject[:flags][:cancelable]).to eq true
        end

        it 'contains cancel path' do
          expect(subject[:cancel_path]).to be_present
        end
      end

      context 'user does not have ability to cancel pipeline' do
        it 'cancelable flag is false' do
          expect(subject[:flags][:cancelable]).to eq false
        end

        it 'does not contain cancel path' do
          expect(subject).not_to have_key(:cancel_path)
        end
      end
    end

    context 'when pipeline has YAML errors' do
      let(:pipeline) do
        create(:ci_pipeline, config: { rspec: { invalid: :value } })
      end

      it 'contains flag that indicates there are errors' do
        expect(subject[:flags][:yaml_errors]).to be true
      end

      it 'contains information about error' do
        expect(subject[:yaml_errors]).to be_present
      end
    end

    context 'when pipeline does not have YAML errors' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      it 'contains flag that indicates there are no errors' do
        expect(subject[:flags][:yaml_errors]).to be false
      end

      it 'does not contain field that normally holds an error' do
        expect(subject).not_to have_key(:yaml_errors)
      end
    end

    context 'when pipeline ref is empty' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        allow(pipeline).to receive(:ref).and_return(nil)
      end

      it 'does not generate branch path' do
        expect(subject[:ref][:path]).to be_nil
      end
    end
  end
end
