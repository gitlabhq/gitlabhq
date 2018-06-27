require 'rake_helper'

describe 'clearing redis cache' do
  before do
    Rake.application.rake_require 'tasks/cache'
  end

  describe 'clearing pipeline status cache' do
    let(:pipeline_status) { create(:ci_pipeline).project.pipeline_status }

    before do
      allow(pipeline_status).to receive(:loaded).and_return(nil)
    end

    it 'clears pipeline status cache' do
      expect { run_rake_task('cache:clear:redis') }.to change { pipeline_status.has_cache? }
    end
  end
end
