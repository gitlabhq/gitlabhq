# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TriggeredPipelineEntity, feature_category: :continuous_integration do
  include Gitlab::Routing

  let_it_be(:pipeline) { build_stubbed(:ci_pipeline) }
  let_it_be(:user) { build_stubbed(:user) }

  let(:request) { double('request', current_user: user) }
  let(:options) { {} }
  let(:entity) { described_class.represent(pipeline, request: request, **options) }

  describe '#as_json' do
    subject { entity.as_json }

    it do
      is_expected.to(
        include(
          :id, :iid, :active, :coverage, :details, :name, :path, :project,
          :source, :source_job, :user
        )
      )
    end

    context 'when coverage is disabled' do
      let(:options) { { disable_coverage: true } }

      it { is_expected.not_to include(:coverage) }
    end
  end
end
