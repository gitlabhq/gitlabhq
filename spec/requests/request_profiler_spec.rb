# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Request Profiler' do
  let(:user) { create(:user) }

  shared_examples 'profiling a request' do |profile_type, extension|
    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(RubyProf::Profile).to receive(:profile) do |&blk|
        blk.call
        RubyProf::Profile.new
      end
      allow(MemoryProfiler).to receive(:report) do |&blk|
        blk.call
        MemoryProfiler.start
        MemoryProfiler.stop
      end
    end

    it 'creates a profile of the request' do
      project = create(:project, namespace: user.namespace)
      time    = Time.now
      path    = "/#{project.full_path}"

      travel_to(time) do
        get path, params: {}, headers: { 'X-Profile-Token' => Gitlab::RequestProfiler.profile_token, 'X-Profile-Mode' => profile_type }
      end

      profile_type = 'execution' if profile_type.nil?
      profile_path = "#{Gitlab.config.shared.path}/tmp/requests_profiles/#{path.tr('/', '|')}_#{time.to_i}_#{profile_type}.#{extension}"
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

    include_examples 'profiling a request', 'execution', 'html'
    include_examples 'profiling a request', nil, 'html'
    include_examples 'profiling a request', 'memory', 'txt'
  end

  context "when user is not logged-in" do
    include_examples 'profiling a request', 'execution', 'html'
    include_examples 'profiling a request', nil, 'html'
    include_examples 'profiling a request', 'memory', 'txt'
  end
end
