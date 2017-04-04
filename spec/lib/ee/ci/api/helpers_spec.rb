require 'spec_helper'

describe EE::Ci::API::Helpers do
  let(:helper) { Class.new { include Ci::API::Helpers }.new }

  before do
    allow(helper).to receive(:env).and_return({})
  end

  describe '#authenticate_build' do
    let(:build) { create(:ci_build) }

    before do
      allow(helper).to receive(:validate_build!)
    end

    it 'handles sticking of a build when a build ID is specified' do
      allow(helper).to receive(:params).and_return(id: build.id)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware).
        to receive(:stick_or_unstick).
        with({}, :build, build.id)

      helper.authenticate_build!
    end

    it 'does not handle sticking if no build ID was specified' do
      allow(helper).to receive(:params).and_return({})

      expect(Gitlab::Database::LoadBalancing::RackMiddleware).
        not_to receive(:stick_or_unstick)

      helper.authenticate_build!
    end

    it 'returns the build if one could be found' do
      allow(helper).to receive(:params).and_return(id: build.id)

      expect(helper.authenticate_build!).to eq(build)
    end
  end

  describe '#current_runner' do
    let(:runner) { create(:ci_runner, token: 'foo') }

    it 'handles sticking of a runner if a token is specified' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(Gitlab::Database::LoadBalancing::RackMiddleware).
        to receive(:stick_or_unstick).
        with({}, :runner, runner.token)

      helper.current_runner
    end

    it 'does not handle sticking if no token was specified' do
      allow(helper).to receive(:params).and_return({})

      expect(Gitlab::Database::LoadBalancing::RackMiddleware).
        not_to receive(:stick_or_unstick)

      helper.current_runner
    end

    it 'returns the runner if one could be found' do
      allow(helper).to receive(:params).and_return(token: runner.token)

      expect(helper.current_runner).to eq(runner)
    end
  end
end
