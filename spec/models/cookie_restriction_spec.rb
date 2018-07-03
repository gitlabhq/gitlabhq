require 'spec_helper'

describe CookieRestriction do
  subject { described_class.new(:my_feature) }

  before do
    allow(Feature).to receive(:enabled?).and_call_original
  end

  describe "#cookie_name" do
    it "returns the name of the enable cookie" do
      expect(subject.cookie_name).to eq "enable_my_feature"
    end
  end

  describe "#cookie_feature" do
    it "returns a feature name used to lift the cookie restriction" do
      expect(subject.cookie_feature).to eq :skip_my_feature_cookie_restriction
    end
  end

  describe "#cookie_required?" do
    it "defaults to requiring a cookie" do
      expect(subject.cookie_required?).to eq true
    end

    context "with the restriction disabled" do
      before do
        stub_feature_flags(skip_my_feature_cookie_restriction: true)
      end

      it "doesn't require a cookie set to use the feature" do
        expect(subject.cookie_required?).to eq false
      end
    end
  end

  describe "#active?" do
    it "is false by default when the cookie is not present" do
      cookies = {}

      expect(subject.active?(cookies)).to be_falsey
    end

    it "looks up cookies to enable the feature" do
      cookies = { 'enable_my_feature' => "true" }

      expect(subject.active?(cookies)).to eq true
    end

    it "can be disabled by cookie" do
      cookies = { 'enable_my_feature' => "false" }

      expect(subject.active?(cookies)).to eq false
    end

    it "is true when the cookie restriction has been lifted" do
      stub_feature_flags(skip_my_feature_cookie_restriction: true)
      cookies = []

      expect(subject.active?(cookies)).to eq true
    end
  end
end
