# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509IssuerCrlCheckWorker, feature_category: :source_code_management do
  subject(:worker) { described_class.new }

  let(:project) { create(:project, :public, :repository) }
  let(:x509_signed_commit) { project.commit_by(oid: '189a6c924013fc3fe40d6f1ec1dc20214183bc97') }
  let(:revoked_x509_signed_commit) { project.commit_by(oid: 'ed775cc81e5477df30c2abba7b6fdbb5d0baadae') }

  describe '#perform' do
    context 'valid crl' do
      before do
        stub_request(:get, "http://ch.siemens.com/pki?ZZZZZZA6.crl")
          .to_return(status: 200, body: File.read('spec/fixtures/x509/ZZZZZZA6.crl'), headers: {})
      end

      it 'changes certificate status for revoked certificates' do
        revoked_x509_commit = Gitlab::X509::Commit.new(revoked_x509_signed_commit)
        x509_commit = Gitlab::X509::Commit.new(x509_signed_commit)
        issuer = revoked_x509_commit.signature.x509_certificate.x509_issuer

        expect(issuer).to eq(x509_commit.signature.x509_certificate.x509_issuer)
        expect(revoked_x509_commit.signature.x509_certificate.good?).to be_truthy
        expect(x509_commit.signature.x509_certificate.good?).to be_truthy

        worker.perform
        revoked_x509_commit.signature.reload

        expect(revoked_x509_commit.signature.x509_certificate.revoked?).to be_truthy
        expect(x509_commit.signature.x509_certificate.revoked?).to be_falsey
      end
    end

    context 'invalid crl' do
      before do
        stub_request(:get, "http://ch.siemens.com/pki?ZZZZZZA6.crl")
          .to_return(status: 200, body: "trash", headers: {})
      end

      it 'does not change certificate status' do
        revoked_x509_commit = Gitlab::X509::Commit.new(revoked_x509_signed_commit)

        expect(revoked_x509_commit.signature.x509_certificate.good?).to be_truthy

        worker.perform
        revoked_x509_commit.signature.reload

        expect(revoked_x509_commit.signature.x509_certificate.revoked?).to be_falsey
      end
    end

    context 'not found crl' do
      before do
        stub_request(:get, "http://ch.siemens.com/pki?ZZZZZZA6.crl")
          .to_return(status: 404, body: "not found", headers: {})
      end

      it 'does not change certificate status' do
        revoked_x509_commit = Gitlab::X509::Commit.new(revoked_x509_signed_commit)

        expect(revoked_x509_commit.signature.x509_certificate.good?).to be_truthy

        worker.perform
        revoked_x509_commit.signature.reload

        expect(revoked_x509_commit.signature.x509_certificate.revoked?).to be_falsey
      end
    end

    context 'unreachable crl' do
      before do
        stub_request(:get, "http://ch.siemens.com/pki?ZZZZZZA6.crl")
          .to_raise(SocketError.new('Some HTTP error'))
      end

      it 'does not change certificate status' do
        revoked_x509_commit = Gitlab::X509::Commit.new(revoked_x509_signed_commit)

        expect(revoked_x509_commit.signature.x509_certificate.good?).to be_truthy

        worker.perform
        revoked_x509_commit.signature.reload

        expect(revoked_x509_commit.signature.x509_certificate.revoked?).to be_falsey
      end
    end
  end
end
