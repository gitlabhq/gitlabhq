# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FeatureCategories do
  let(:fake_categories) { %w[foo bar] }

  subject(:feature_categories) { described_class.new(fake_categories) }

  describe "#valid?" do
    it "returns true if category is known", :aggregate_failures do
      expect(subject.valid?('foo')).to be(true)
      expect(subject.valid?('zzz')).to be(false)
    end
  end

  describe '#get!' do
    subject { feature_categories.get!(category) }

    let(:category) { 'foo' }

    it { is_expected.to eq('foo') }

    context 'when category does not exist' do
      let(:category) { 'zzz' }

      it { expect { subject }.to raise_error(RuntimeError) }

      context 'when on production' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
        end

        it { is_expected.to eq('unknown') }
      end
    end
  end

  describe "#from_request" do
    let(:request_env) { {} }
    let(:verified) { true }

    def fake_request(request_feature_category)
      double('request', env: request_env, headers: { "HTTP_X_GITLAB_FEATURE_CATEGORY" => request_feature_category })
    end

    before do
      allow(::Gitlab::RequestForgeryProtection).to receive(:verified?).with(request_env).and_return(verified)
    end

    it "returns category from request when valid, otherwise returns nil", :aggregate_failures do
      expect(subject.from_request(fake_request("foo"))).to be("foo")
      expect(subject.from_request(fake_request("zzz"))).to be_nil
    end

    context "when request is not verified" do
      let(:verified) { false }

      it "returns nil" do
        expect(subject.from_request(fake_request("foo"))).to be_nil
      end
    end
  end

  describe "#categories" do
    it "returns a set of the given categories" do
      expect(subject.categories).to be_a(Set)
      expect(subject.categories).to contain_exactly(*fake_categories)
    end
  end

  describe ".load_from_yaml" do
    subject { described_class.load_from_yaml }

    it "creates FeatureCategories from feature_categories.yml file" do
      contents = YAML.load_file(Rails.root.join('config', 'feature_categories.yml'))

      expect(subject.categories).to contain_exactly(*contents)
    end
  end

  describe ".default" do
    it "returns a memoization of load_from_yaml", :aggregate_failures do
      # FeatureCategories.default could have been referenced in another spec, so we need to clean it up here
      described_class.instance_variable_set(:@default, nil)

      expect(described_class).to receive(:load_from_yaml).once.and_call_original

      2.times { described_class.default }

      # Uses reference equality to verify memoization
      expect(described_class.default).to equal(described_class.default)
      expect(described_class.default).to be_a(described_class)
    end
  end
end
