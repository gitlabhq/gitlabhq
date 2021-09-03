# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProjectNamespace, type: :model do
  describe 'relationships' do
    it { is_expected.to have_one(:project).with_foreign_key(:project_namespace_id).inverse_of(:project_namespace) }
  end
end
