# frozen_string_literal: true

require 'spec_helper'

describe ChatNotificationWorker do
  let(:worker) { described_class.new }
  let(:chat_build) do
    create(:ci_build, pipeline: create(:ci_pipeline, source: :chat))
  end

  it 'instructs sidekiq not to retry on failure' do
    expect(described_class.get_sidekiq_options['retry']).to eq(false)
  end

  describe '#perform' do
    it 'does nothing when the build no longer exists' do
      expect(worker).not_to receive(:send_response)

      worker.perform(-1)
    end

    it 'sends a response for an existing build' do
      expect(worker)
        .to receive(:send_response)
        .with(an_instance_of(Ci::Build))

      worker.perform(chat_build.id)
    end

    context 'when the trace sections could not be found' do
      it 'reschedules the job' do
        expect(worker)
          .to receive(:send_response)
          .and_raise(Gitlab::Chat::Output::MissingBuildSectionError)

        expect(described_class)
          .to receive(:perform_in)
          .with(described_class::RESCHEDULE_INTERVAL, chat_build.id, 1)

        worker.perform(chat_build.id)
      end

      it "raises an error after #{described_class::RESCHEDULE_TIMEOUT} seconds of retrying" do
        allow(described_class).to receive(:new).and_return(worker)
        allow(worker).to receive(:send_response).and_raise(Gitlab::Chat::Output::MissingBuildSectionError)

        worker.perform(chat_build.id)

        expect { described_class.drain }.to raise_error(described_class::TimeoutExceeded)

        max_reschedules = described_class::RESCHEDULE_TIMEOUT / described_class::RESCHEDULE_INTERVAL

        expect(worker).to have_received(:send_response).exactly(max_reschedules + 1).times
      end
    end
  end

  describe '#send_response' do
    context 'when a responder could not be found' do
      it 'does nothing' do
        expect(Gitlab::Chat::Responder)
          .to receive(:responder_for)
          .with(chat_build)
          .and_return(nil)

        expect(worker.send_response(chat_build)).to be_nil
      end
    end

    context 'when a responder could be found' do
      let(:responder) { double(:responder) }

      before do
        allow(Gitlab::Chat::Responder)
          .to receive(:responder_for)
          .with(chat_build)
          .and_return(responder)
      end

      it 'sends the response for a succeeded build' do
        output = double(:output, to_s: 'this is the build output')

        expect(chat_build)
          .to receive(:success?)
          .and_return(true)

        expect(responder)
          .to receive(:success)
          .with(an_instance_of(String))

        expect(Gitlab::Chat::Output)
          .to receive(:new)
          .with(chat_build)
          .and_return(output)

        worker.send_response(chat_build)
      end

      it 'sends the response for a failed build' do
        expect(chat_build)
          .to receive(:success?)
          .and_return(false)

        expect(responder).to receive(:failure)

        worker.send_response(chat_build)
      end
    end
  end
end
