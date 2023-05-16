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

      let(:domain) { create(:pages_domain, *traits) }

      it { expect(presenter.needs_verification?).to eq(expected) }
    end
  end

  describe 'show_auto_ssl_failed_warning?' do
    subject { presenter.show_auto_ssl_failed_warning? }

    let(:domain) { create(:pages_domain) }

    before do
      stub_lets_encrypt_settings
    end

    it { is_expected.to eq(false) }

    context "when we failed to obtain Let's Encrypt's certificate" do
      before do
        domain.update!(auto_ssl_failed: true)
      end

      it { is_expected.to eq(true) }

      context "when Let's Encrypt integration is disabled" do
        before do
          allow(::Gitlab::LetsEncrypt).to receive(:enabled?).and_return false
        end

        it { is_expected.to eq(false) }
      end

      context "when domain is unverified" do
        before do
          domain.update!(verified_at: nil)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe 'user_defined_certificate?' do
    subject { presenter.user_defined_certificate? }

    let(:domain) { create(:pages_domain) }

    context "when domain certificate is user provided" do
      it { is_expected.to eq(true) }
    end

    context "when domain is not persisted" do
      before do
        domain.destroy!
      end

      it { is_expected.to eq(false) }
    end

    context "when domain certificate is blank" do
      before do
        domain.update!(certificate: nil, key: nil)
      end

      it { is_expected.to eq(false) }
    end

    context "when domain certificate source is gitlab_provided" do
      before do
        domain.update!(certificate_source: :gitlab_provided)
      end

      it { is_expected.to eq(false) }
    end

    context "when domain certificate has error" do
      before do
        domain.errors.add(:certificate, "certificate error")
      end

      it { is_expected.to eq(false) }
    end
  end
end
