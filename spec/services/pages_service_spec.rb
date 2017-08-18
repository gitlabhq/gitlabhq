require 'spec_helper'

describe PagesService do
  let(:build) { create(:ci_build) }
  let(:data) { Gitlab::DataBuilder::Build.build(build) }
  let(:service) { described_class.new(data) }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
  end

  context 'execute asynchronously for pages job' do
    before do
      build.name = 'pages'
    end

    context 'on success' do
      before do
        build.success
      end

      it 'executes worker' do
        expect(PagesWorker).to receive(:perform_async)
        service.execute
      end
    end

    %w(pending running failed canceled).each do |status|
      context "on #{status}" do
        before do
          build.status = status
        end

        it 'does not execute worker' do
          expect(PagesWorker).not_to receive(:perform_async)
          service.execute
        end
      end
    end
  end

  context 'for other jobs' do
    before do
      build.name = 'other job'
      build.success
    end

    it 'does not execute worker' do
      expect(PagesWorker).not_to receive(:perform_async)
      service.execute
    end
  end
end
