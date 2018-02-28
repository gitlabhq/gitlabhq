require 'spec_helper'

# We stub Gitaly in `spec/support/gitaly.rb` for other tests. We don't want
# those stubs while testing the GitalyClient itself.
describe Gitlab::GitalyClient, skip_gitaly_mock: true do
  describe '.stub_class' do
    it 'returns the gRPC health check stub' do
      expect(described_class.stub_class(:health_check)).to eq(::Grpc::Health::V1::Health::Stub)
    end

    it 'returns a Gitaly stub' do
      expect(described_class.stub_class(:ref_service)).to eq(::Gitaly::RefService::Stub)
    end
  end

  describe '.stub_address' do
    it 'returns the same result after being called multiple times' do
      address = 'localhost:9876'
      prefixed_address = "tcp://#{address}"

      allow(Gitlab.config.repositories).to receive(:storages).and_return({
        'default' => { 'gitaly_address' => prefixed_address }
      })

      2.times do
        expect(described_class.stub_address('default')).to eq('localhost:9876')
      end
    end
  end

  describe '.stub' do
    # Notice that this is referring to gRPC "stubs", not rspec stubs
    before do
      described_class.clear_stubs!
    end

    context 'when passed a UNIX socket address' do
      it 'passes the address as-is to GRPC' do
        address = 'unix:/tmp/gitaly.sock'
        allow(Gitlab.config.repositories).to receive(:storages).and_return({
          'default' => { 'gitaly_address' => address }
        })

        expect(Gitaly::CommitService::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit_service, 'default')
      end
    end

    context 'when passed a TCP address' do
      it 'strips tcp:// prefix before passing it to GRPC::Core::Channel initializer' do
        address = 'localhost:9876'
        prefixed_address = "tcp://#{address}"

        allow(Gitlab.config.repositories).to receive(:storages).and_return({
          'default' => { 'gitaly_address' => prefixed_address }
        })

        expect(Gitaly::CommitService::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit_service, 'default')
      end
    end
  end

  describe 'allow_n_plus_1_calls' do
    context 'when RequestStore is enabled', :request_store do
      it 'returns the result of the allow_n_plus_1_calls block' do
        expect(described_class.allow_n_plus_1_calls { "result" }).to eq("result")
      end
    end

    context 'when RequestStore is not active' do
      it 'returns the result of the allow_n_plus_1_calls block' do
        expect(described_class.allow_n_plus_1_calls { "something" }).to eq("something")
      end
    end
  end

  describe 'enforce_gitaly_request_limits?' do
    def call_gitaly(count = 1)
      (1..count).each do
        described_class.enforce_gitaly_request_limits(:test)
      end
    end

    context 'when RequestStore is enabled', :request_store do
      it 'allows up the maximum number of allowed calls' do
        expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS) }.not_to raise_error
      end

      context 'when the maximum number of calls has been reached' do
        before do
          call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS)
        end

        it 'fails on the next call' do
          expect { call_gitaly(1) }.to raise_error(Gitlab::GitalyClient::TooManyInvocationsError)
        end
      end

      it 'allows the maximum number of calls to be exceeded within an allow_n_plus_1_calls block' do
        expect do
          described_class.allow_n_plus_1_calls do
            call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1)
          end
        end.not_to raise_error
      end

      context 'when the maximum number of calls has been reached within an allow_n_plus_1_calls block' do
        before do
          described_class.allow_n_plus_1_calls do
            call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS)
          end
        end

        it 'allows up to the maximum number of calls outside of an allow_n_plus_1_calls block' do
          expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS) }.not_to raise_error
        end

        it 'does not allow the maximum number of calls to be exceeded outside of an allow_n_plus_1_calls block' do
          expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1) }.to raise_error(Gitlab::GitalyClient::TooManyInvocationsError)
        end
      end
    end

    context 'when RequestStore is not active' do
      it 'does not raise errors when the maximum number of allowed calls is exceeded' do
        expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 2) }.not_to raise_error
      end

      it 'does not fail when the maximum number of calls is exceeded within an allow_n_plus_1_calls block' do
        expect do
          described_class.allow_n_plus_1_calls do
            call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1)
          end
        end.not_to raise_error
      end
    end
  end

  describe 'get_request_count' do
    context 'when RequestStore is enabled', :request_store do
      context 'when enforce_gitaly_request_limits is called outside of allow_n_plus_1_calls blocks' do
        before do
          described_class.enforce_gitaly_request_limits(:call)
        end

        it 'counts gitaly calls' do
          expect(described_class.get_request_count).to eq(1)
        end
      end

      context 'when enforce_gitaly_request_limits is called inside and outside of allow_n_plus_1_calls blocks' do
        before do
          described_class.enforce_gitaly_request_limits(:call)
          described_class.allow_n_plus_1_calls do
            described_class.enforce_gitaly_request_limits(:call)
          end
        end

        it 'counts gitaly calls' do
          expect(described_class.get_request_count).to eq(2)
        end
      end

      context 'when reset_counts is called' do
        before do
          described_class.enforce_gitaly_request_limits(:call)
          described_class.reset_counts
        end

        it 'resets counts' do
          expect(described_class.get_request_count).to eq(0)
        end
      end
    end

    context 'when RequestStore is not active' do
      before do
        described_class.enforce_gitaly_request_limits(:call)
      end

      it 'returns zero' do
        expect(described_class.get_request_count).to eq(0)
      end
    end
  end

  describe 'feature_enabled?' do
    let(:feature_name) { 'my_feature' }
    let(:real_feature_name) { "gitaly_#{feature_name}" }

    context 'when Gitaly is disabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
      end

      it 'returns false' do
        expect(described_class.feature_enabled?(feature_name)).to be(false)
      end
    end

    context 'when the feature status is DISABLED' do
      let(:feature_status) { Gitlab::GitalyClient::MigrationStatus::DISABLED }

      it 'returns false' do
        expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
      end
    end

    context 'when the feature_status is OPT_IN' do
      let(:feature_status) { Gitlab::GitalyClient::MigrationStatus::OPT_IN }

      context "when the feature flag hasn't been set" do
        it 'returns false' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end
      end

      context "when the feature flag is set to disable" do
        before do
          Feature.get(real_feature_name).disable
        end

        it 'returns false' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end
      end

      context "when the feature flag is set to enable" do
        before do
          Feature.get(real_feature_name).enable
        end

        it 'returns true' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(true)
        end
      end

      context "when the feature flag is set to a percentage of time" do
        before do
          Feature.get(real_feature_name).enable_percentage_of_time(70)
        end

        it 'bases the result on pseudo-random numbers' do
          expect(Random).to receive(:rand).and_return(0.3)
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(true)

          expect(Random).to receive(:rand).and_return(0.8)
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end
      end

      context "when a feature is not persisted" do
        it 'returns false when opt_into_all_features is off' do
          allow(Feature).to receive(:persisted?).and_return(false)
          allow(described_class).to receive(:opt_into_all_features?).and_return(false)

          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end

        it 'returns true when the override is on' do
          allow(Feature).to receive(:persisted?).and_return(false)
          allow(described_class).to receive(:opt_into_all_features?).and_return(true)

          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(true)
        end
      end
    end

    context 'when the feature_status is OPT_OUT' do
      let(:feature_status) { Gitlab::GitalyClient::MigrationStatus::OPT_OUT }

      context "when the feature flag hasn't been set" do
        it 'returns true' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(true)
        end
      end

      context "when the feature flag is set to disable" do
        before do
          Feature.get(real_feature_name).disable
        end

        it 'returns false' do
          expect(described_class.feature_enabled?(feature_name, status: feature_status)).to be(false)
        end
      end
    end
  end

  describe 'timeouts' do
    context 'with default values' do
      before do
        stub_application_setting(gitaly_timeout_default: 55)
        stub_application_setting(gitaly_timeout_medium: 30)
        stub_application_setting(gitaly_timeout_fast: 10)
      end

      it 'returns expected values' do
        expect(described_class.default_timeout).to be(55)
        expect(described_class.medium_timeout).to be(30)
        expect(described_class.fast_timeout).to be(10)
      end
    end
  end
end
