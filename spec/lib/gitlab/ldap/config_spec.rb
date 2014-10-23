require 'spec_helper'

describe Gitlab::LDAP::Config do
  let(:config) { Gitlab::LDAP::Config.new provider }
  let(:provider) { 'ldapmain' }

  describe :initalize do
    it 'requires a provider' do
      expect{ Gitlab::LDAP::Config.new }.to raise_error ArgumentError
    end

    it "works" do
      expect(config).to be_a described_class
    end

    it "raises an error if a unknow provider is used" do
      expect{ Gitlab::LDAP::Config.new 'unknown' }.to raise_error
    end

    context "if 'ldap' is the provider name" do
      let(:provider) { 'ldap' }

      context "and 'ldap' is not in defined as a provider" do
        before { Gitlab::LDAP::Config.stub(providers: %w{ldapmain}) }

        it "uses the first provider" do
          # Fetch the provider_name attribute from 'options' so that we know
          # that the 'options' Hash is not empty/nil.
          expect(config.options['provider_name']).to eq('ldapmain')
        end
      end
    end
  end
end
