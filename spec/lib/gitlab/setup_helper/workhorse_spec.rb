# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SetupHelper::Workhorse do
  describe '.make' do
    subject { described_class.make }

    context 'when there is a gmake' do
      it 'returns gmake' do
        expect(Gitlab::Popen).to receive(:popen).with(%w[which gmake]).and_return(['/usr/bin/gmake', 0])

        expect(subject).to eq 'gmake'
      end
    end

    context 'when there is no gmake' do
      it 'returns make' do
        expect(Gitlab::Popen).to receive(:popen).with(%w[which gmake]).and_return(['', 1])

        expect(subject).to eq 'make'
      end
    end
  end
end
