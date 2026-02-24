# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::LabelBasic, feature_category: :team_planning do
  describe '#as_json' do
    subject { described_class.new(label).as_json }

    describe '#archived' do
      let(:label) { build_stubbed(:label, archived: true) }

      it { is_expected.to include(:archived) }
    end
  end
end
