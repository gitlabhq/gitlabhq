# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DatabaseReflection do
  describe '.reflect' do
    it 'returns a Reflection instance' do
      expect(User.database).to be_an_instance_of(Gitlab::Database::Reflection)
    end

    it 'memoizes the result' do
      instance1 = User.database
      instance2 = User.database

      expect(instance1).to equal(instance2)
    end
  end
end
