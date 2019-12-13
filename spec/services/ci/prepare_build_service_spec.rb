# frozen_string_literal: true

require 'spec_helper'

describe Ci::PrepareBuildService do
  describe '#execute' do
    let(:build) { create(:ci_build, :preparing) }

    subject { described_class.new(build).execute }

    before do
      allow(build).to receive(:prerequisites).and_return(prerequisites)
    end

    shared_examples 'build enqueueing' do
      it 'enqueues the build' do
        expect(build).to receive(:enqueue).once

        subject
      end
    end

    context 'build has unmet prerequisites' do
      let(:prerequisite) { double(complete!: true) }
      let(:prerequisites) { [prerequisite] }

      it 'completes each prerequisite' do
        expect(prerequisites).to all(receive(:complete!))

        subject
      end

      include_examples 'build enqueueing'

      context 'prerequisites fail to complete' do
        before do
          allow(build).to receive(:enqueue).and_return(false)
        end

        it 'drops the build' do
          expect(build).to receive(:drop).with(:unmet_prerequisites).once

          subject
        end
      end

      context 'prerequisites raise an error' do
        before do
          allow(prerequisite).to receive(:complete!).and_raise Kubeclient::HttpError.new(401, 'unauthorized', nil)
        end

        it 'drops the build and notifies Sentry' do
          expect(build).to receive(:drop).with(:unmet_prerequisites).once
          expect(Gitlab::Sentry).to receive(:track_exception)
            .with(instance_of(Kubeclient::HttpError), hash_including(build_id: build.id))

          subject
        end
      end
    end

    context 'build has no prerequisites' do
      let(:prerequisites) { [] }

      include_examples 'build enqueueing'
    end
  end
end
