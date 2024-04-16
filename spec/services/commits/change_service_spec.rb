# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commits::ChangeService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject(:service) do
    described_class.new(project, user)
  end

  describe '#commit_message' do
    it 'raises NotImplementedError' do
      expect { service.commit_message }.to raise_error(NotImplementedError)
    end
  end
end
