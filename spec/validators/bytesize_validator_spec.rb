# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BytesizeValidator do
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :content
      alias_method :content_before_type_cast, :content

      validates :content, bytesize: { maximum: -> { 7 } }
    end.new
  end

  using RSpec::Parameterized::TableSyntax

  where(:content, :validity, :errors) do
    'short'     | true  | {}
    'very long' | false | { content: ['is too long (9 B). The maximum size is 7 B.'] }
    'short😁' | false | { content: ['is too long (9 B). The maximum size is 7 B.'] }
    'short⇏' | false | { content: ['is too long (8 B). The maximum size is 7 B.'] }
  end

  with_them do
    before do
      model.content = content
      model.validate
    end

    it { expect(model.valid?).to eq(validity) }
    it { expect(model.errors.messages).to eq(errors) }
  end
end
