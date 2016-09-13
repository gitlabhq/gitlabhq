require 'spec_helper'

describe PipelinesEmailService do
  let(:data) do
    Gitlab::DataBuilder::Pipeline.build(create(:ci_pipeline))
  end

  let(:recipient) { 'test@gitlab.com' }

  def expect_pipeline_service
    expect_any_instance_of(Ci::SendPipelineNotificationService)
  end

  def receive_execute
    receive(:execute).with([recipient])
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }

      context 'when pusher is added' do
        before do
          subject.add_pusher = true
        end

        it { is_expected.not_to validate_presence_of(:recipients) }
      end
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

  describe '#test' do
    before do
      subject.recipients = recipient
    end

    shared_examples 'sending email' do
      it 'sends email' do
        expect_pipeline_service.to receive_execute

        subject.test(data)
      end
    end

    it_behaves_like 'sending email'

    context 'when pipeline is succeeded' do
      before do
        data[:object_attributes][:status] = 'success'
      end

      it_behaves_like 'sending email'
    end
  end

  describe '#execute' do
    context 'with recipients' do
      before do
        subject.recipients = recipient
      end

      it 'sends email for failed pipeline' do
        data[:object_attributes][:status] = 'failed'

        expect_pipeline_service.to receive_execute

        subject.execute(data)
      end

      it 'does not send email for succeeded pipeline' do
        data[:object_attributes][:status] = 'success'

        expect_pipeline_service.not_to receive_execute

        subject.execute(data)
      end

      context 'with notify_only_broken_pipelines on' do
        before do
          subject.notify_only_broken_pipelines = true
        end

        it 'sends email for failed pipeline' do
          data[:object_attributes][:status] = 'failed'

          expect_pipeline_service.to receive_execute

          subject.execute(data)
        end
      end
    end

    it 'does not send email when recipients list is empty' do
      subject.recipients = ' ,, '
      data[:object_attributes][:status] = 'failed'

      expect_pipeline_service.not_to receive_execute

      subject.execute(data)
    end
  end
end
