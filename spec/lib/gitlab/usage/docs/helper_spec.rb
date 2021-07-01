# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Docs::Helper do
  subject(:helper) { klass.new }

  let_it_be(:klass) do
    Class.new do
      include Gitlab::Usage::Docs::Helper
    end
  end

  let(:metric_definition) do
    {
      data_category: 'Standard',
      name: 'test_metric',
      description: description,
      product_group: 'group::product intelligence',
      status: 'data_available',
      tier: %w(free premium)
    }
  end

  let(:description) { 'Metric description' }

  describe '#render_name' do
    it { expect(helper.render_name(metric_definition[:name])).to eq('### `test_metric`') }
  end

  describe '#render_description' do
    context 'without description' do
      let(:description) { nil }

      it { expect(helper.render_description(metric_definition)).to eq('Missing description') }
    end

    context 'without description' do
      it { expect(helper.render_description(metric_definition)).to eq('Metric description') }
    end
  end

  describe '#render_yaml_link' do
    let(:yaml_link) { 'config/metrics/license/test_metric.yml' }
    let(:expected) { "[YAML definition](#{yaml_link})" }

    it { expect(helper.render_yaml_link(yaml_link)).to eq(expected) }
  end

  describe '#render_status' do
    let(:expected) { "Status: `data_available`" }

    it { expect(helper.render_status(metric_definition)).to eq(expected) }
  end

  describe '#render_owner' do
    let(:expected) { "Group: `group::product intelligence`" }

    it { expect(helper.render_owner(metric_definition)).to eq(expected) }
  end

  describe '#render_tiers' do
    let(:expected) { "Tiers: `free`, `premium`" }

    it { expect(helper.render_tiers(metric_definition)).to eq(expected) }
  end

  describe '#render_data_category' do
    let(:expected) { 'Data Category: `Standard`' }

    it { expect(helper.render_data_category(metric_definition)).to eq(expected) }
  end

  describe '#render_owner' do
    let(:expected) { "Group: `group::product intelligence`" }

    it { expect(helper.render_owner(metric_definition)).to eq(expected) }
  end
end
