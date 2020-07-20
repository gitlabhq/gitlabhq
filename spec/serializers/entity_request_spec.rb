# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EntityRequest do
  subject do
    described_class.new(user: 'user', project: 'some project')
  end

  describe 'methods created' do
    it 'defines accessible attributes' do
      expect(subject.user).to eq 'user'
      expect(subject.project).to eq 'some project'
    end

    it 'raises error when attribute is not defined' do
      expect { subject.some_method }.to raise_error NoMethodError
    end
  end
end
