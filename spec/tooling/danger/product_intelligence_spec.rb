# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/product_intelligence'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::ProductIntelligence do
  include_context "with dangerfile"

  subject(:product_intelligence) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:changed_files) { ['metrics/counts_7d/test_metric.yml', 'doc/development/usage_ping/dictionary.md'] }
  let(:changed_lines) { ['+tier: ee'] }

  before do
    allow(fake_helper).to receive(:all_changed_files).and_return(changed_files)
    allow(fake_helper).to receive(:changed_lines).and_return(changed_lines)
  end

  describe '#need_dictionary_changes?' do
    subject { product_intelligence.need_dictionary_changes? }

    context 'when changed files do not contain dictionary changes' do
      let(:changed_files) { ['config/metrics/counts_7d/test_metric.yml'] }

      it { is_expected.to be true }
    end

    context 'when changed files already contains dictionary changes' do
      let(:changed_files) { ['doc/development/usage_ping/dictionary.md'] }

      it { is_expected.to be false }
    end
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

      before do
        allow(fake_helper).to receive(:mr_has_labels?).with('product intelligence').and_return(true)
      end

      it { is_expected.to match_array(expected_labels) }
    end

    context 'with product intelligence::review pending' do
      before do
        allow(fake_helper).to receive(:mr_has_labels?).and_return(true)
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#matching_changed_files' do
    subject { product_intelligence.matching_changed_files }

    let(:changed_files) do
      [
        'dashboard/todos_controller.rb',
        'components/welcome.vue',
        'admin/groups/_form.html.haml'
      ]
    end

    context 'with snowplow files changed' do
      context 'when vue file changed' do
        let(:changed_lines) { ['+data-track-event'] }

        it { is_expected.to match_array(['components/welcome.vue']) }
      end

      context 'when haml file changed' do
        let(:changed_lines) { ['+ data: { track_label:'] }

        it { is_expected.to match_array(['admin/groups/_form.html.haml']) }
      end

      context 'when ruby file changed' do
        let(:changed_lines) { ['+ Gitlab::Tracking.event'] }
        let(:changed_files) { ['dashboard/todos_controller.rb', 'admin/groups/_form.html.haml'] }

        it { is_expected.to match_array(['dashboard/todos_controller.rb']) }
      end
    end

    context 'with dictionary file not changed' do
      it { is_expected.to be_empty }
    end

    context 'with metrics files changed' do
      let(:changed_files) { ['config/metrics/counts_7d/test_metric.yml', 'ee/config/metrics/counts_7d/ee_metric.yml'] }

      it { is_expected.to match_array(changed_files) }
    end

    context 'with metrics files not changed' do
      it { is_expected.to be_empty }
    end

    context 'with tracking files changed' do
      let(:changed_files) do
        [
          'lib/gitlab/tracking.rb',
          'spec/lib/gitlab/tracking_spec.rb',
          'app/helpers/tracking_helper.rb'
        ]
      end

      it { is_expected.to match_array(changed_files) }
    end

    context 'with usage_data files changed' do
      let(:changed_files) do
        [
          'doc/api/usage_data.md',
          'ee/lib/ee/gitlab/usage_data.rb',
          'spec/lib/gitlab/usage_data_spec.rb'
        ]
      end

      it { is_expected.to match_array(changed_files) }
    end
  end
end
