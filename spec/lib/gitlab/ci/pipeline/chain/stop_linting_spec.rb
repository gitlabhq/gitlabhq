# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::StopLinting, feature_category: :pipeline_composition do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline, reload: true) { create(:ci_pipeline, project: project) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      ignore_skip_ci: false,
      save_incompleted: true,
      linting: linting)
  end

  subject(:step) { described_class.new(pipeline, command) }

  describe '#break?' do
    subject(:break?) { step.break? }

    context 'on linting' do
      let(:linting) { true }

      it 'breaks the chain' do
        expect(break?).to be true
      end
    end

    context 'on not linting' do
      let(:linting) { false }

      it 'does not break the chain' do
        expect(break?).to be false
      end
    end
  end
end
