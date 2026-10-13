# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::MergeRequestAuthor, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  let(:author) { build_stubbed(:user, user_type: user_type) }

  subject(:json) { described_class.new(author).as_json }

  where(:user_type, :bot) do
    :human           | false
    :project_bot     | true
    :service_account | true
  end

  with_them do
    it 'includes the bot status alongside the basic user fields' do
      expect(json).to eq(API::Entities::UserBasic.new(author).as_json.merge(bot: bot))
    end
  end
end
