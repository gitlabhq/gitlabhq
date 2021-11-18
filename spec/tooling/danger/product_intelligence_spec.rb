# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/product_intelligence'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::ProductIntelligence do
  include_context "with dangerfile"

  subject(:product_intelligence) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:changed_files) { ['metrics/counts_7d/test_metric.yml'] }
  let(:changed_lines) { ['+tier: ee'] }

  before do
    allow(fake_helper).to receive(:all_changed_files).and_return(changed_files)
    allow(fake_helper).to receive(:changed_lines).and_return(changed_lines)
  end

  describe '#missing_labels' do
    subject { product_intelligence.missing_labels }

    let(:ci_env) { true }

    before do
      allow(fake_helper).to receive(:mr_has_labels?).and_return(false)
      allow(fake_helper).to receive(:ci?).and_return(ci_env)
    end

    context 'with ci? false' do
      let(:ci_env) { false }

      it { is_expected.to be_empty }
    end

    context 'with ci? true' do
      let(:expected_labels) { ['product intelligence', 'product intelligence::review pending'] }

      it { is_expected.to match_array(expected_labels) }
    end

    context 'with product intelligence label' do
      let(:expected_labels) { ['product intelligence::review pending'] }
      let(:mr_labels) { [] }

      before do
        allow(fake_helper).to receive(:mr_has_labels?).with('product intelligence').and_return(true)
        allow(fake_helper).to receive(:mr_labels).and_return(mr_labels)
      end

      it { is_expected.to match_array(expected_labels) }

      context 'with product intelligence::review pending' do
        let(:mr_labels) { ['product intelligence::review pending'] }

        it { is_expected.to be_empty }
      end

      context 'with product intelligence::approved' do
        let(:mr_labels) { ['product intelligence::approved'] }

        it { is_expected.to be_empty }
      end
    end

    context 'with growth experiment label' do
      before do
        allow(fake_helper).to receive(:mr_has_labels?).with('growth experiment').and_return(true)
      end

      it { is_expected.to be_empty }
    end
  end
end
