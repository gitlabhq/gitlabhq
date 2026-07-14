# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RelativePositioning, feature_category: :team_planning do
  describe '.parse_move_between_ids' do
    using RSpec::Parameterized::TableSyntax

    where(:before_id, :after_id, :expected) do
      5    | 10   | [5, 10]
      5    | nil  | [5, nil]
      nil  | 10   | [nil, 10]
      '5'  | '10' | [5, 10]
      0    | 10   | [nil, 10]
      -1   | 10   | [nil, 10]
      nil  | nil  | nil
      0    | 0    | nil
    end

    with_them do
      it { expect(described_class.parse_move_between_ids(before_id, after_id)).to eq(expected) }
    end
  end
end
