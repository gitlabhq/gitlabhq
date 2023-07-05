# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HtmlSafetyValidator do
  let(:validator) { described_class.new(attributes: [:name]) }
  let(:group) { build(:group) }

  def validate(value)
    validator.validate_each(group, :name, value)
  end

  it 'adds an error when a script is included in the name' do
    validate('My group <script>evil_script</script>')

    expect(group.errors[:name]).to eq([described_class.error_message])
  end

  it 'does not add an error when an ampersand is included in the name' do
    validate('Group with 1 & 2')

    expect(group.errors).to be_empty
  end
end
