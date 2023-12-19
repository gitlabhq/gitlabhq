# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Transitionable, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  let(:klass) do
    Class.new do
      include Transitionable

      def initialize(transitioning)
        @transitioning = transitioning
      end

      def project
        Project.new
      end
    end
  end

  let(:object) { klass.new(transitioning) }

  describe '#transitioning?' do
    context "when trasnitioning" do
      let(:transitioning) { true }

      it { expect(object.transitioning?).to eq(true) }
    end

    context "when not trasnitioning" do
      let(:transitioning) { false }

      it { expect(object.transitioning?).to eq(false) }
    end
  end
end
