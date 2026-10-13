# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomainPresenter, feature_category: :pages do
  using RSpec::Parameterized::TableSyntax
  include LetsEncryptHelpers

  let(:presenter) { Gitlab::View::Presenter::Factory.new(domain).fabricate! }

  describe 'needs_validation?' do
    where(:pages_verification_enabled, :traits, :expected) do
      false | :unverified | false
      false | []          | false
      true  | :unverified | true
      true  | []          | false
    end

    with_them do
      before do
        stub_application_setting(pages_domain_verification_enabled: pages_verification_enabled)
      end

      let(:domain) { build_stubbed(:pages_domain, *traits) }

      it { expect(presenter.needs_verification?).to eq(expected) }
    end
  end

  describe 'show_auto_ssl_failed_warning?' do
    subject { presenter.show_auto_ssl_failed_warning? }

    let(:domain) { build_stubbed(:pages_domain) }

    before do
      stub_lets_encrypt_settings
    end

    it { is_expected.to be(false) }

    context "when we failed to obtain Let's Encrypt's certificate" do
      let(:domain) { build_stubbed(:pages_domain, auto_ssl_failed: true) }

      it { is_expected.to be(true) }

      context "when Let's Encrypt integration is disabled" do
        before do
          allow(::Gitlab::LetsEncrypt).to receive(:enabled?).and_return false
        end

        it { is_expected.to be(false) }
      end

      context "when domain is unverified" do
        let(:domain) { build_stubbed(:pages_domain, auto_ssl_failed: true, verified_at: nil) }

        it { is_expected.to be(false) }
      end
    end
  end

  describe 'user_defined_certificate?' do
    subject { presenter.user_defined_certificate? }

    let(:domain) { build_stubbed(:pages_domain) }

    context "when domain certificate is user provided" do
      it { is_expected.to be(true) }
    end

    context "when domain is not persisted" do
      let(:domain) { build(:pages_domain) }

      it { is_expected.to be(false) }
    end

    context "when domain certificate is blank" do
      let(:domain) { build_stubbed(:pages_domain, certificate: nil, key: nil) }

      it { is_expected.to be(false) }
    end

    context "when domain certificate source is gitlab_provided" do
      let(:domain) { build_stubbed(:pages_domain, certificate_source: :gitlab_provided) }

      it { is_expected.to be(false) }
    end

    context "when domain certificate has error" do
      before do
        domain.errors.add(:certificate, "certificate error")
      end

      it { is_expected.to be(false) }
    end
  end
end
