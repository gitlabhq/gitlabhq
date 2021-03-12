# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::InProductMarketing do
  include EmailSpec::Matchers
  include InProductMarketingHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  describe '#in_product_marketing_email' do
    using RSpec::Parameterized::TableSyntax

    where(:track, :series) do
      :create | 0
      :create | 1
      :create | 2
      :verify | 0
      :verify | 1
      :verify | 2
      :trial  | 0
      :trial  | 1
      :trial  | 2
      :team   | 0
      :team   | 1
      :team   | 2
    end

    with_them do
      subject { Notify.in_product_marketing_email(user.id, group.id, track, series) }

      it 'has the correct subject and content' do
        aggregate_failures do
          is_expected.to have_subject(subject_line(track, series))
          is_expected.to have_body_text(in_product_marketing_title(track, series))
          is_expected.to have_body_text(in_product_marketing_subtitle(track, series))
          is_expected.to have_body_text(in_product_marketing_cta_text(track, series))
        end
      end
    end
  end
end
