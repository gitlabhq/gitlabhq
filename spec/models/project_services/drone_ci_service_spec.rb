require 'spec_helper'

describe DroneCiService, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:service_hook) }
  end

  describe 'validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:drone_url) }
      it_behaves_like 'issue tracker service URL attribute', :drone_url
    end

    context 'inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:drone_url) }
    end
  end

  shared_context :drone_ci_service do
    let(:drone)      { DroneCiService.new }
    let(:project)    { create(:project, :repository, name: 'project') }
    let(:path)       { project.full_path }
    let(:drone_url)  { 'http://drone.example.com' }
    let(:sha)        { '2ab7834c' }
    let(:branch)     { 'dev' }
    let(:token)      { 'secret' }
    let(:iid)        { rand(1..9999) }

    # URL's
    let(:build_page) { "#{drone_url}/gitlab/#{path}/redirect/commits/#{sha}?branch=#{branch}" }
    let(:commit_status_path) { "#{drone_url}/gitlab/#{path}/commits/#{sha}?branch=#{branch}&access_token=#{token}" }

    before do
      allow(drone).to receive_messages(
        project_id: project.id,
        project: project,
        active: true,
        drone_url: drone_url,
        token: token
      )
    end

    def stub_request(status: 200, body: nil)
      body ||= %q({"status":"success"})

      WebMock.stub_request(:get, commit_status_path).to_return(
        status: status,
        headers: { 'Content-Type' => 'application/json' },
        body: body
      )
    end
  end

  describe "service page/path methods" do
    include_context :drone_ci_service

    it { expect(drone.build_page(sha, branch)).to eq(build_page) }
    it { expect(drone.commit_status_path(sha, branch)).to eq(commit_status_path) }
  end

  describe '#commit_status' do
    include_context :drone_ci_service

    it 'returns the contents of the reactive cache' do
      stub_reactive_cache(drone, { commit_status: 'foo' }, 'sha', 'ref')

      expect(drone.commit_status('sha', 'ref')).to eq('foo')
    end
  end

  describe '#calculate_reactive_cache' do
    include_context :drone_ci_service

    context '#commit_status' do
      subject { drone.calculate_reactive_cache(sha, branch)[:commit_status] }

      it 'sets commit status to :error when status is 500' do
        stub_request(status: 500)

        is_expected.to eq(:error)
      end

      it 'sets commit status to :error when status is 404' do
        stub_request(status: 404)

        is_expected.to eq(:error)
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
    include_context :drone_ci_service

    let(:user)    { create(:user, username: 'username') }
    let(:push_sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    it do
      service_hook = double
      expect(service_hook).to receive(:execute)
      expect(drone).to receive(:service_hook).and_return(service_hook)

      drone.execute(push_sample_data)
    end
  end
end
