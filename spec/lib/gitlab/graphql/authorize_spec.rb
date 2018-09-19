require 'spec_helper'

describe Gitlab::Graphql::Authorize do
  describe '#authorize' do
    it 'adds permissions from subclasses to those of superclasses when used on classes' do
      base_class = Class.new do
        extend Gitlab::Graphql::Authorize

        authorize :base_authorization
      end
      sub_class = Class.new(base_class) do
        authorize :sub_authorization
      end

      expect(base_class.required_permissions).to contain_exactly(:base_authorization)
      expect(sub_class.required_permissions)
        .to contain_exactly(:base_authorization, :sub_authorization)
    end
  end
end
