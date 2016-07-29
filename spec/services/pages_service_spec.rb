require 'spec_helper'

describe PagesService, services: true do
  let(:build) { create(:ci_build) }
  let(:data) { Gitlab::BuildDataBuilder.build(build) }
  let(:service) { PagesService.new(data) }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
  end

  context 'execute asynchronously for pages job' do
    before { build.name = 'pages' }

    context 'on success' do
      before { build.success }

      it 'should execute worker' do
        expect(PagesWorker).to receive(:perform_async)
        service.execute
      end
    end

    %w(pending running failed canceled).each do |status|
      context "on #{status}" do
        before { build.status = status }

        it 'should not execute worker' do
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

    it 'should not execute worker' do
      expect(PagesWorker).not_to receive(:perform_async)
      service.execute
    end
  end
end
