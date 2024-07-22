# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authorize::AuthorizeResource do
  let(:fake_class) do
    Class.new do
      include Gitlab::Graphql::Authorize::AuthorizeResource

      attr_reader :user, :found_object, :scope_validator

      authorize :read_the_thing

      def initialize(user, found_object, scope_validator)
        @user = user
        @found_object = found_object
        @scope_validator = scope_validator
      end

      def find_object
        found_object
      end

      def current_user
        user
      end

      def context
        { current_user: user, scope_validator: scope_validator }
      end

      def self.authorization
        @authorization ||= ::Gitlab::Graphql::Authorize::ObjectAuthorization.new(required_permissions)
      end
    end
  end

  let(:user) { build(:user) }
  let(:scope_validator) { instance_double(::Gitlab::Auth::ScopeValidator, valid_for?: true) }
  let(:project) { build(:project) }

  subject(:loading_resource) { fake_class.new(user, project, scope_validator) }

  before do
    # don't allow anything by default
    allow(Ability).to receive(:allowed?).and_return(false)
  end

  context 'when the user is allowed to perform the action' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :read_the_thing, project).and_return(true)
    end

    describe '#authorized_find!' do
      it 'returns the object' do
        expect(loading_resource.authorized_find!).to eq(project)
      end
    end

    describe '#authorize!' do
      it 'does not raise an error' do
        expect { loading_resource.authorize!(project) }.not_to raise_error
      end
    end
  end

  context 'when the user is not allowed to perform the action' do
    describe '#authorized_find!' do
      it 'raises an error' do
        expect { loading_resource.authorized_find! }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    describe '#authorize!' do
      it 'raises an error' do
        expect { loading_resource.authorize!(project) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end

  describe '#find_object' do
    let(:fake_class) do
      Class.new { include Gitlab::Graphql::Authorize::AuthorizeResource }
    end

    let(:id) { "id" }
    let(:return_value) { "return value" }

    it 'calls GitlabSchema.find_by_gid' do
      expect(GitlabSchema).to receive(:find_by_gid).with(id).and_return(return_value)
      expect(fake_class.new.find_object(id: id)).to be return_value
    end
  end

  describe '#authorize' do
    it 'adds permissions from subclasses to those of superclasses when used on classes' do
      base_class = Class.new do
        include Gitlab::Graphql::Authorize::AuthorizeResource

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

  describe 'authorizes_object?' do
    it 'is false by default' do
      a_class = Class.new do
        include Gitlab::Graphql::Authorize::AuthorizeResource
      end

      expect(a_class).not_to be_authorizes_object
    end

    it 'is true after calling authorizes_object!' do
      a_class = Class.new do
        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorizes_object!
      end

      expect(a_class).to be_authorizes_object
    end

    it 'is true if a parent authorizes_object' do
      parent = Class.new do
        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorizes_object!
      end

      child = Class.new(parent)

      expect(child).to be_authorizes_object
    end
  end

  describe '#authorized_resource?' do
    let(:object) { :object }

    it 'delegates to authorization' do
      expect(fake_class.authorization).to be_kind_of(::Gitlab::Graphql::Authorize::ObjectAuthorization)
      expect(fake_class.authorization).to receive(:ok?)
        .with(object, user, scope_validator: scope_validator)

      fake_class.new(user, :found_object, scope_validator).authorized_resource?(object)
    end
  end
end
