# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::Trial do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  subject(:message) { described_class.new(group: group, user: user, series: series)}

  describe "public methods" do
    where(series: [0, 1, 2])

    with_them do
      it 'returns value for series', :aggregate_failures do
        expect(message.subject_line).to be_present
        expect(message.tagline).to be_present
        expect(message.title).to be_present
        expect(message.subtitle).to be_present
        expect(message.body_line1).to be_present
        expect(message.body_line2).to be_present
        expect(message.cta_text).to be_present
      end
    end
  end
end
