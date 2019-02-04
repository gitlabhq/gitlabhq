# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::Kubernetes::Helm::Certificate do
  describe '.generate_root' do
    subject { described_class.generate_root }

    it 'should generate a root CA that expires a long way in the future' do
      expect(subject.cert.not_after).to be > 999.years.from_now
    end
  end

  describe '#issue' do
    subject { described_class.generate_root.issue }

    it 'should generate a cert that expires soon' do
      expect(subject.cert.not_after).to be < 60.minutes.from_now
    end

    context 'passing in INFINITE_EXPIRY' do
      subject { described_class.generate_root.issue(expires_in: described_class::INFINITE_EXPIRY) }

      it 'should generate a cert that expires a long way in the future' do
        expect(subject.cert.not_after).to be > 999.years.from_now
      end
    end
  end
end
