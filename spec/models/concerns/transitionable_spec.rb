# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Transitionable, feature_category: :code_review_workflow do
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

  describe 'For a class' do
    using RSpec::Parameterized::TableSyntax

    describe '#transitioning?' do
      where(:transitioning, :feature_flag, :result) do
        true  | true  | true
        false | false | false
        true  | false | false
        false | true  | false
      end

      with_them do
        before do
          stub_feature_flags(skip_validations_during_transitions: feature_flag)
        end

        it { expect(object.transitioning?).to eq(result) }
      end
    end
  end
end
