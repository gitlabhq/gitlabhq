# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::DeployTokenAuthor do
  describe '#initialize' do
    it 'sets correct attributes' do
      expect(described_class.new(name: 'Lorem deploy token'))
        .to have_attributes(id: -2, name: 'Lorem deploy token')
    end

    it 'sets default name when it is not provided' do
      expect(described_class.new)
        .to have_attributes(id: -2, name: 'Deploy Token')
    end
  end
end
