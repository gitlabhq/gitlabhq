# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Hook, feature_category: :pipeline_composition do
  let_it_be(:build1) do
    build(
      :ci_build,
      options: { hooks: { pre_get_sources_script: ["echo 'hello pre_get_sources_script'"] } }
    )
  end

  describe '.from_hooks' do
    subject(:from_hooks) { described_class.from_hooks(build1) }

    it 'initializes and returns hooks' do
      expect(from_hooks.size).to eq(1)
      expect(from_hooks[0].name).to eq('pre_get_sources_script')
      expect(from_hooks[0].script).to eq(["echo 'hello pre_get_sources_script'"])
    end
  end
end
