require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170503004427_update_retried_for_ci_build.rb')

describe UpdateRetriedForCiBuild, :delete do
  let(:pipeline) { create(:ci_pipeline) }
  let!(:build_old) { create(:ci_build, pipeline: pipeline, name: 'test') }
  let!(:build_new) { create(:ci_build, pipeline: pipeline, name: 'test') }

  before do
    described_class.new.up
  end

  it 'updates ci_builds.is_retried' do
    expect(build_old.reload).to be_retried
    expect(build_new.reload).not_to be_retried
  end
end
