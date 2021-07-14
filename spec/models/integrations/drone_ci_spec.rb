# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::DroneCi, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

  describe 'validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:drone_url) }
      it_behaves_like 'issue tracker integration URL attribute', :drone_url
    end

    context 'inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:drone_url) }
    end
  end

  shared_context :drone_ci_integration do
    subject(:drone) do
      described_class.new(
        project: project,
        active: true,
        drone_url: drone_url,
        token: token
      )
    end

    let(:project)    { create(:project, :repository, name: 'project') }
    let(:path)       { project.full_path }
    let(:drone_url)  { 'http://drone.example.com' }
    let(:sha)        { '2ab7834c' }
    let(:branch)     { 'dev' }
    let(:token)      { 'secret' }
    let(:iid)        { rand(1..9999) }

    # URLs
    let(:build_page) { "#{drone_url}/gitlab/#{path}/redirect/commits/#{sha}?branch=#{branch}" }
    let(:commit_status_path) { "#{drone_url}/gitlab/#{path}/commits/#{sha}?branch=#{branch}&access_token=#{token}" }

    def stub_request(status: 200, body: nil)
      body ||= %q({"status":"success"})

      WebMock.stub_request(:get, commit_status_path).to_return(
        status: status,
        headers: { 'Content-Type' => 'application/json' },
        body: body
      )
    end
  end

  it_behaves_like Integrations::HasWebHook do
    include_context :drone_ci_integration

    let(:integration) { drone }
    let(:hook_url) { "#{drone_url}/hook?owner=#{project.namespace.full_path}&name=#{project.path}&access_token=#{token}" }

    it 'does not create a hook if project is not present' do
      integration.project = nil
      integration.instance = true

      expect { integration.save! }.not_to change(ServiceHook, :count)
    end
  end

  describe "integration page/path methods" do
    include_context :drone_ci_integration

    it { expect(drone.build_page(sha, branch)).to eq(build_page) }
    it { expect(drone.commit_status_path(sha, branch)).to eq(commit_status_path) }
  end

  describe '#commit_status' do
    include_context :drone_ci_integration

    it 'returns the contents of the reactive cache' do
      stub_reactive_cache(drone, { commit_status: 'foo' }, 'sha', 'ref')

      expect(drone.commit_status('sha', 'ref')).to eq('foo')
    end
  end

  describe '#calculate_reactive_cache' do
    include_context :drone_ci_integration

    describe '#commit_status' do
      subject { drone.calculate_reactive_cache(sha, branch)[:commit_status] }

      it 'sets commit status to :error when status is 500' do
        stub_request(status: 500)

        is_expected.to eq(:error)
      end

      it 'sets commit status to :error when status is 404' do
        stub_request(status: 404)

        is_expected.to eq(:error)
      end

      Gitlab::HTTP::HTTP_ERRORS.each do |http_error|
        it "sets commit status to :error with a #{http_error.name} error" do
          WebMock.stub_request(:get, commit_status_path)
            .to_raise(http_error)

          expect(Gitlab::ErrorTracking)
            .to receive(:log_exception)
            .with(instance_of(http_error), project_id: project.id)

          is_expected.to eq(:error)
        end
      end

      {
        "killed"  => :canceled,
        "failure" => :failed,
        "error"   => :failed,
        "success" => "success"
      }.each do |drone_status, our_status|
        it "sets commit status to #{our_status.inspect} when returned status is #{drone_status.inspect}" do
          stub_request(body: %Q({"status":"#{drone_status}"}))

          is_expected.to eq(our_status)
        end
      end
    end
  end

  describe "execute" do
    include_context :drone_ci_integration

    let(:user) { create(:user, username: 'username') }
    let(:push_sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    it 'executes the webhook' do
      expect(drone).to receive(:execute_web_hook!).with(push_sample_data)

      drone.execute(push_sample_data)
    end

    it 'does not try to execute the webhook if the integration is not in a project' do
      drone.project = nil
      drone.instance = true

      expect(drone).not_to receive(:execute_web_hook!)

      drone.execute(push_sample_data)
    end
  end
end
