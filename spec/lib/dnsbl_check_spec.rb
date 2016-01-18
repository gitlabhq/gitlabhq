require 'spec_helper'
require 'ostruct'

describe 'DNSBLCheck', lib: true, no_db: true do
  let(:spam_ip)    { '127.0.0.2' }
  let(:no_spam_ip) { '127.0.0.3' }
  let(:invalid_ip) { 'a.b.c.d' }
  let(:dnsbl_check) { DNSBLCheck.create_from_config(OpenStruct.new({ enabled: true, lists: [OpenStruct.new({ domain: 'test', weight: 1 })] })) }

  before(:context) do
    class DNSBLCheck::Resolver
      class << self
        alias :old_search :search
        def search(query)
          return true  if query.match(/\A2\.0\.0\.127\./)
          return false if query.match(/\A3\.0\.0\.127\./)
        end
      end
    end
  end

  describe '#threshold=' do
    it { expect{ dnsbl_check.threshold = 0   }.to     raise_error(ArgumentError) }
    it { expect{ dnsbl_check.threshold = 1.1 }.to     raise_error(ArgumentError) }
    it { expect{ dnsbl_check.threshold = 0.5 }.not_to raise_error }
  end

  describe '#test' do
    it { expect{ dnsbl_check.test(invalid_ip) }.to raise_error(ArgumentError) }

    it { expect(dnsbl_check.test(spam_ip)).to    be_truthy }
    it { expect(dnsbl_check.test(no_spam_ip)).to be_falsey }
  end

  describe '#test_strict' do
    before do
      dnsbl_check.threshold = 1
    end

    it { expect{ dnsbl_check.test_strict(invalid_ip) }.to raise_error(ArgumentError) }

    it { expect(dnsbl_check.test(spam_ip)).to    be_falsey }
    it { expect(dnsbl_check.test(no_spam_ip)).to be_falsey }
    it { expect(dnsbl_check.test_strict(spam_ip)).to    be_truthy }
    it { expect(dnsbl_check.test_strict(no_spam_ip)).to be_falsey }
  end
end
