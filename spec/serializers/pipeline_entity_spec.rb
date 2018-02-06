require 'spec_helper'

describe PipelineEntity do
  set(:user) { create(:user) }
  let(:request) { double('request') }

  before do
    stub_not_protect_default_branch

    allow(request).to receive(:current_user).and_return(user)
  end

  let(:entity) do
    described_class.represent(pipeline, request: request)
  end

  describe '#as_json' do
    subject { entity.as_json }

    context 'when pipeline is empty' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      it 'contains required fields' do
        expect(subject).to include :id, :user, :path, :coverage, :source
        expect(subject).to include :ref, :commit
        expect(subject).to include :updated_at, :created_at
      end

      it 'contains details' do
        expect(subject).to include :details
        expect(subject[:details])
          .to include :duration, :finished_at
        expect(subject[:details][:status]).to include :icon, :favicon, :text, :label
      end

      it 'contains flags' do
        expect(subject).to include :flags
        expect(subject[:flags])
          .to include :latest, :stuck, :auto_devops,
                      :yaml_errors, :retryable, :cancelable
      end
    end

    context 'when pipeline is retryable' do
      let(:project) { create(:project) }

      let(:pipeline) do
        create(:ci_pipeline, status: :success, project: project)
      end

      before do
        create(:ci_build, :failed, pipeline: pipeline)
      end

      context 'user has ability to retry pipeline' do
        before do
          project.add_developer(user)
        end

        it 'contains retry path' do
          expect(subject[:retry_path]).to be_present
        end
      end

      context 'user does not have ability to retry pipeline' do
        it 'does not contain retry path' do
          expect(subject).not_to have_key(:retry_path)
        end
      end
    end

    context 'when pipeline is cancelable' do
      let(:project) { create(:project) }

      let(:pipeline) do
        create(:ci_pipeline, status: :running, project: project)
      end

      before do
        create(:ci_build, :pending, pipeline: pipeline)
      end

      context 'user has ability to cancel pipeline' do
        before do
          project.add_developer(user)
        end

        it 'contains cancel path' do
          expect(subject[:cancel_path]).to be_present
        end
      end

      context 'user does not have ability to cancel pipeline' do
        it 'does not contain cancel path' do
          expect(subject).not_to have_key(:cancel_path)
        end
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

    context 'when pipeline has a failure reason set' do
      let(:pipeline) { create(:ci_empty_pipeline) }

      before do
        pipeline.drop!(:config_error)
      end

      it 'has a correct failure reason' do
        expect(subject[:failure_reason])
          .to eq 'CI/CD YAML configuration error!'
      end
    end
  end
end
