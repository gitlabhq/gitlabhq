# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ProjectConfig::Source, feature_category: :continuous_integration do
  let_it_be(:custom_config_class) { Class.new(described_class) }
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:sha) { '123456' }

  subject(:custom_config) { custom_config_class.new(project: project, sha: sha) }

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
end
