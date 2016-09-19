require 'spec_helper'

describe PipelinesEmailService do
  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit('master').sha)
  end

  let(:project) { create(:project) }
  let(:recipient) { 'test@gitlab.com' }

  let(:data) do
    Gitlab::DataBuilder::Pipeline.build(pipeline)
  end

  before do
    reset_delivered_emails!
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:recipients) }
    end
  end

  describe '#test_data' do
    let(:build)   { create(:ci_build) }
    let(:project) { build.project }
    let(:user)    { create(:user) }

    before do
      project.team << [user, :developer]
    end

    it 'builds test data' do
      data = subject.test_data(project, user)

      expect(data[:object_kind]).to eq('pipeline')
    end
  end

  shared_examples 'sending email' do
    before do
      perform_enqueued_jobs do
        run
      end
    end

    it 'sends email' do
      sent_to = ActionMailer::Base.deliveries.flat_map(&:to)
      expect(sent_to).to contain_exactly(recipient)
    end
  end

  shared_examples 'not sending email' do
    before do
      perform_enqueued_jobs do
        run
      end
    end

    it 'does not send email' do
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe '#test' do
    def run
      subject.test(data)
    end

    before do
      subject.recipients = recipient
    end

    context 'when pipeline is failed' do
      before do
        data[:object_attributes][:status] = 'failed'
        pipeline.update(status: 'failed')
      end

      it_behaves_like 'sending email'
    end

    context 'when pipeline is succeeded' do
      before do
        data[:object_attributes][:status] = 'success'
        pipeline.update(status: 'success')
      end

      it_behaves_like 'sending email'
    end
  end

  describe '#execute' do
    def run
      subject.execute(data)
    end

    context 'with recipients' do
      before do
        subject.recipients = recipient
      end

      context 'with failed pipeline' do
        before do
          data[:object_attributes][:status] = 'failed'
          pipeline.update(status: 'failed')
        end

        it_behaves_like 'sending email'
      end

      context 'with succeeded pipeline' do
        before do
          data[:object_attributes][:status] = 'success'
          pipeline.update(status: 'success')
        end

        it_behaves_like 'not sending email'
      end

      context 'with notify_only_broken_pipelines on' do
        before do
          subject.notify_only_broken_pipelines = true
        end

        context 'with failed pipeline' do
          before do
            data[:object_attributes][:status] = 'failed'
            pipeline.update(status: 'failed')
          end

          it_behaves_like 'sending email'
        end

        context 'with succeeded pipeline' do
          before do
            data[:object_attributes][:status] = 'success'
            pipeline.update(status: 'success')
          end

          it_behaves_like 'not sending email'
        end
      end
    end

    context 'with empty recipients list' do
      before do
        subject.recipients = ' ,, '
      end

      context 'with failed pipeline' do
        before do
          data[:object_attributes][:status] = 'failed'
          pipeline.update(status: 'failed')
        end

        it_behaves_like 'not sending email'
      end
    end
  end
end
