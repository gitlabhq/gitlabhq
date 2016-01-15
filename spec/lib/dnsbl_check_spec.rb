require 'spec_helper'

describe 'DNSBLChecker', lib: true, no_db: true do
  let(:spam_ip)    { '127.0.0.2' }
  let(:no_spam_ip) { '127.0.0.3' }
  let(:invalid_ip) { 'a.b.c.d' }

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

    DNSBLCheck.add_dnsbl('test', 1)
  end

  describe '#treshold=' do
    it { expect{ DNSBLCheck.treshold = 0   }.to     raise_error(ArgumentError) }
    it { expect{ DNSBLCheck.treshold = 1.1 }.to     raise_error(ArgumentError) }
    it { expect{ DNSBLCheck.treshold = 0.5 }.not_to raise_error }
  end

  describe '#test' do
    it { expect{ DNSBLCheck.test(invalid_ip) }.to raise_error(ArgumentError) }

    it { expect(DNSBLCheck.test(spam_ip)).to    be_truthy }
    it { expect(DNSBLCheck.test(no_spam_ip)).to be_falsey }
  end

  describe '#test_strict' do
    before(:context) do
      DNSBLCheck.treshold = 1
    end

    it { expect{ DNSBLCheck.test_strict(invalid_ip) }.to raise_error(ArgumentError) }

    it { expect(DNSBLCheck.test(spam_ip)).to    be_falsey }
    it { expect(DNSBLCheck.test(no_spam_ip)).to be_falsey }
    it { expect(DNSBLCheck.test_strict(spam_ip)).to    be_truthy }
    it { expect(DNSBLCheck.test_strict(no_spam_ip)).to be_falsey }
  end
end
