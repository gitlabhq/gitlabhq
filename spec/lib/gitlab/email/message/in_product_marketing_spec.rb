# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing do
  describe '.for' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.for(track) }

    context 'when track exists' do
      where(:track, :expected_class) do
        :create | described_class::Create
        :verify | described_class::Verify
        :trial  | described_class::Trial
        :team   | described_class::Team
      end

      with_them do
        it { is_expected.to eq(expected_class) }
      end
    end

    context 'when track does not exist' do
      let(:track) { :non_existent }

      it 'raises error' do
        expect { subject }.to raise_error(described_class::UnknownTrackError)
      end
    end
  end
end
