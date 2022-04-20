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

  describe '#check!' do
    subject { product_intelligence.check! }

    let(:markdown_formatted_list) { 'markdown formatted list' }
    let(:review_pending_label) { 'product intelligence::review pending' }
    let(:approved_label) { 'product intelligence::approved' }
    let(:ci_env) { true }
    let(:previous_label_to_add) { 'label_to_add' }
    let(:labels_to_add) { [previous_label_to_add] }
    let(:has_product_intelligence_label) { true }

    before do
      allow(fake_helper).to receive(:changes_by_category).and_return(product_intelligence: changed_files, database: ['other_files.yml'])
      allow(fake_helper).to receive(:ci?).and_return(ci_env)
      allow(fake_helper).to receive(:mr_has_labels?).with('product intelligence').and_return(has_product_intelligence_label)
      allow(fake_helper).to receive(:markdown_list).with(changed_files).and_return(markdown_formatted_list)
      allow(fake_helper).to receive(:labels_to_add).and_return(labels_to_add)
    end

    shared_examples "doesn't add new labels" do
      it "doesn't add new labels" do
        subject

        expect(labels_to_add).to match_array [previous_label_to_add]
      end
    end

    shared_examples "doesn't add new warnings" do
      it "doesn't add new warnings" do
        expect(product_intelligence).not_to receive(:warn)

        subject
      end
    end

    shared_examples 'adds new labels' do
      it 'adds new labels' do
        subject

        expect(labels_to_add).to match_array [previous_label_to_add, review_pending_label]
      end
    end

    context 'with growth experiment label' do
      before do
        allow(fake_helper).to receive(:mr_has_labels?).with('growth experiment').and_return(true)
      end

      include_examples "doesn't add new labels"
      include_examples "doesn't add new warnings"
    end

    context 'without growth experiment label' do
      before do
        allow(fake_helper).to receive(:mr_has_labels?).with('growth experiment').and_return(false)
      end

      context 'with approved label' do
        let(:mr_labels) { [approved_label] }

        include_examples "doesn't add new labels"
        include_examples "doesn't add new warnings"
      end

      context 'without approved label' do
        include_examples 'adds new labels'

        it 'warns with proper message' do
          expect(product_intelligence).to receive(:warn).with(%r{#{markdown_formatted_list}})

          subject
        end
      end

      context 'with product intelligence::review pending label' do
        let(:mr_labels) { ['product intelligence::review pending'] }

        include_examples "doesn't add new labels"
      end

      context 'with product intelligence::approved label' do
        let(:mr_labels) { ['product intelligence::approved'] }

        include_examples "doesn't add new labels"
      end

      context 'with the product intelligence label' do
        let(:has_product_intelligence_label) { true }

        context 'with ci? false' do
          let(:ci_env) { false }

          include_examples "doesn't add new labels"
        end

        context 'with ci? true' do
          include_examples 'adds new labels'
        end
      end
    end
  end
end
