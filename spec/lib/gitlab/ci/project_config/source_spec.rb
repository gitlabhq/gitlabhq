# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ProjectConfig::Source, feature_category: :pipeline_composition do
  let_it_be(:custom_config_class) { Class.new(described_class) }
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:sha) { '123456' }
  let_it_be(:inputs) { {} }

  subject(:custom_config) { custom_config_class.new(project: project, sha: sha, inputs: inputs) }

  describe '#content' do
    subject(:content) { custom_config.content }

    it { expect { content }.to raise_error(NotImplementedError) }
  end

  describe '#source' do
    subject(:source) { custom_config.source }

    it { expect { source }.to raise_error(NotImplementedError) }
  end

  describe '#internal_include_prepended?' do
    subject(:internal_include_prepended) { custom_config.internal_include_prepended? }

    it { expect(internal_include_prepended).to eq(false) }
  end

  describe '#inputs_for_pipeline_creation' do
    let(:inputs) { { 'foo' => 'bar' } }

    subject(:inputs_for_pipeline_creation) { custom_config.inputs_for_pipeline_creation }

    it { expect(inputs_for_pipeline_creation).to eq(inputs) }
  end
end
