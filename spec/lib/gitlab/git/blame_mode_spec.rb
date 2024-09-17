# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::BlameMode, feature_category: :source_code_management do
  subject(:blame_mode) { described_class.new(project, params) }

  let_it_be(:project) { build(:project) }
  let(:params) { {} }

  describe '#streaming?' do
    subject { blame_mode.streaming? }

    it { is_expected.to be_falsey }

    context 'when streaming param is provided' do
      let(:params) { { streaming: true } }

      it { is_expected.to be_truthy }
    end
  end

  describe '#pagination?' do
    subject { blame_mode.pagination? }

    it { is_expected.to be_truthy }

    context 'when `streaming` params is enabled' do
      let(:params) { { streaming: true } }

      it { is_expected.to be_falsey }
    end

    context 'when `no_pagination` param is provided' do
      let(:params) { { no_pagination: true } }

      it { is_expected.to be_falsey }
    end
  end

  describe '#full?' do
    subject { blame_mode.full? }

    it { is_expected.to be_falsey }
  end
end
