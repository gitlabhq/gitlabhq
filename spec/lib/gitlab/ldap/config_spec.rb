require 'spec_helper'

describe Gitlab::LDAP::Config, lib: true do
  let(:config) { Gitlab::LDAP::Config.new provider }
  let(:provider) { 'ldapmain' }

  describe '#initalize' do
    it 'requires a provider' do
      expect{ Gitlab::LDAP::Config.new }.to raise_error ArgumentError
    end

    it "works" do
      expect(config).to be_a described_class
    end

    it "raises an error if a unknow provider is used" do
      expect{ Gitlab::LDAP::Config.new 'unknown' }.to raise_error(RuntimeError)
    end
  end
end
