require 'spec_helper'

<<<<<<< HEAD
<<<<<<< HEAD
describe Gitlab::LDAP::Config, lib: true do
  let(:config) { Gitlab::LDAP::Config.new provider }
=======
describe Gitlab::LDAP::Config do
  let(:config) { described_class.new provider }
>>>>>>> gitlabhq/ce_upstream
=======
describe Gitlab::LDAP::Config do
  let(:config) { described_class.new provider }
>>>>>>> origin/ce_upstream
  let(:provider) { 'ldapmain' }

  describe '#initalize' do
    it 'requires a provider' do
      expect{ described_class.new }.to raise_error ArgumentError
    end

    it "works" do
      expect(config).to be_a described_class
    end

    it "raises an error if a unknow provider is used" do
      expect { described_class.new 'unknown' }.
        to raise_error(described_class::InvalidProvider)
    end
  end
end
