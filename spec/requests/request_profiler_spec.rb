require 'spec_helper'

describe 'Request Profiler' do
  let(:user) { create(:user) }

  shared_examples 'profiling a request' do
    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(RubyProf::Profile).to receive(:profile) do |&blk|
        blk.call
        RubyProf::Profile.new
      end
    end

    it 'creates a profile of the request' do
      project = create(:project, namespace: user.namespace)
      time    = Time.now
      path    = "/#{project.full_path}"

      Timecop.freeze(time) do
        get path, nil, 'X-Profile-Token' => Gitlab::RequestProfiler.profile_token
      end

      profile_path = "#{Gitlab.config.shared.path}/tmp/requests_profiles/#{path.tr('/', '|')}_#{time.to_i}.html"
      expect(File.exist?(profile_path)).to be true
    end

    after do
      Gitlab::RequestProfiler.remove_all_profiles
    end
  end

  context "when user is logged-in" do
    before do
      login_as(user)
    end

    include_examples 'profiling a request'
  end

  context "when user is not logged-in" do
    include_examples 'profiling a request'
  end
end
