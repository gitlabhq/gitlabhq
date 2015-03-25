require "spec_helper"

describe 'RackAttackHelpers' do
  describe 'reset' do
    let(:discriminator) { 'test-key'}
    let(:maxretry) { 5 }
    let(:period) { 1.minute }
    let(:options) { { findtime: period, bantime: 60, maxretry: maxretry } }

    def do_filter
      for i in 1..maxretry - 1 do
        status = Rack::Attack::Allow2Ban.filter(discriminator, options) { true }
        expect(status).to eq(false)
      end
    end

    def do_reset
      Rack::Attack::Allow2Ban.reset(discriminator, options)
    end

    before do
      do_reset
    end

    after do
      do_reset
    end

    it 'user is not banned after n - 1 retries' do
      do_filter
      do_reset
      do_filter
    end
  end
end
