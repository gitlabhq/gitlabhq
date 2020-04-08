# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::TransientEmbedService, :use_clean_rails_memory_store_caching do
  let_it_be(:project) { build(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '.valid_params?' do
    let(:params) { { embedded: 'true', embed_json: '{}' } }

    subject { described_class.valid_params?(params) }

    it { is_expected.to be_truthy }

    context 'missing embedded' do
      let(:params) { { embed_json: '{}' } }

      it { is_expected.to be_falsey }
    end

    context 'not embedded' do
      let(:params) { { embedded: 'false', embed_json: '{}' } }

      it { is_expected.to be_falsey }
    end

    context 'missing embed_json' do
      let(:params) { { embedded: 'true' } }

      it { is_expected.to be_falsey }
    end
  end

  describe '#get_dashboard' do
    let(:embed_json) do
      {
       panel_groups: [{
         panels: [{
           type: 'line-graph',
           title: 'title',
           y_label: 'y_label',
           metrics: [{
             query_range: 'up',
             label: 'y_label'
           }]
         }]
       }]
      }.to_json
    end
    let(:service_params) { [project, user, { environment: environment, embedded: 'true', embed_json: embed_json }] }
    let(:service_call) { described_class.new(*service_params).get_dashboard }

    it_behaves_like 'valid embedded dashboard service response'
    it_behaves_like 'raises error for users with insufficient permissions'

    it 'caches the unprocessed dashboard for subsequent calls' do
      expect_any_instance_of(described_class)
        .to receive(:get_raw_dashboard)
        .once
        .and_call_original

      described_class.new(*service_params).get_dashboard
      described_class.new(*service_params).get_dashboard
    end
  end
end
