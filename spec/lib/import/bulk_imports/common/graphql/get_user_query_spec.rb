# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::Common::Graphql::GetUserQuery, feature_category: :importers do
  subject(:query) { described_class.new }

  it_behaves_like 'a valid Direct Transfer GraphQL query', { id: 'gid://gitlab/User/1' }
end
