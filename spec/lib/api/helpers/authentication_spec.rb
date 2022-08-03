# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Authentication do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }
  let_it_be(:ci_build) { create(:ci_build, :running, user: user) }

  describe 'class methods' do
    subject { Class.new.include(described_class::ClassMethods).new }

    describe '.authenticate_with' do
      it 'sets namespace_inheritable :authentication to correctly when body is empty' do
        expect(subject).to receive(:namespace_inheritable).with(:authentication, {})

        subject.authenticate_with { |allow| }
      end

      it 'sets namespace_inheritable :authentication to correctly when body is not empty' do
        expect(subject).to receive(:namespace_inheritable).with(:authentication, { basic: [:pat, :job], oauth: [:pat, :job] })

        subject.authenticate_with { |allow| allow.token_type(:pat, :job).sent_through(:basic, :oauth) }
      end
    end
  end

  describe 'helper methods' do
    let(:object) do
      cls = Class.new

      class << cls
        def helpers(*modules, &block)
          modules.each { |m| include m }
          include Module.new.tap { |m| m.class_eval(&block) } if block
        end
      end

      cls.define_method(:unauthorized!) { raise '401' }
      cls.define_method(:bad_request!) { |m| raise "400 - #{m}" }

      # Include the helper class methods, as instance methods
      cls.include described_class::ClassMethods

      # Include the methods under test
      cls.include described_class

      cls.new
    end

    describe '#token_from_namespace_inheritable' do
      let(:object) do
        o = super()

        o.instance_eval do
          # It doesn't matter what this returns as long as the method is defined
          def current_request
            nil
          end

          # Spoof Grape's namespace inheritable system
          def namespace_inheritable(key, value = nil)
            return unless key == :authentication

            if value
              @authentication = value
            else
              @authentication
            end
          end
        end

        o
      end

      let(:authentication) do
        object.authenticate_with { |allow| allow.token_types(*resolvers).sent_through(*locators) }
      end

      subject { object.token_from_namespace_inheritable }

      before do
        # Skip validation of token transports and types to simplify testing
        allow(Gitlab::APIAuthentication::TokenLocator).to receive(:new) { |type| type }
        allow(Gitlab::APIAuthentication::TokenResolver).to receive(:new) { |type| type }

        authentication
      end

      shared_examples 'stops early' do |response_method|
        it "calls ##{response_method}" do
          errcls = Class.new(StandardError)
          expect(object).to receive(response_method).and_raise(errcls)
          expect { subject }.to raise_error(errcls)
        end
      end

      shared_examples 'an anonymous request' do
        it 'returns nil' do
          expect(subject).to be(nil)
        end
      end

      shared_examples 'an authenticated request' do
        it 'returns the token' do
          expect(subject).to be(token)
        end
      end

      shared_examples 'an unauthorized request' do
        it_behaves_like 'stops early', :unauthorized!
      end

      context 'with no allowed authentication strategies' do
        let(:authentication) { nil }

        it_behaves_like 'an anonymous request'
      end

      context 'with no located credentials' do
        let(:locators) { [double(extract: nil)] }
        let(:resolvers) { [] }

        it_behaves_like 'an anonymous request'
      end

      context 'with one set of located credentials' do
        let(:locators) { [double(extract: true)] }

        context 'when the credentials contain a valid token' do
          let(:token) { double }
          let(:resolvers) { [double(resolve: token)] }

          it_behaves_like 'an authenticated request'
        end

        context 'when the credentials do not contain a valid token' do
          let(:resolvers) { [double(resolve: nil)] }

          it_behaves_like 'an unauthorized request'
        end
      end

      context 'with multiple located credentials' do
        let(:locators) { [double(extract: true), double(extract: true)] }
        let(:resolvers) { [] }

        it_behaves_like 'stops early', :bad_request!
      end

      context 'when a resolver raises UnauthorizedError' do
        let(:locators) { [double(extract: true)] }
        let(:resolvers) do
          r = double
          expect(r).to receive(:resolve).and_raise(Gitlab::Auth::UnauthorizedError)
          r
        end

        it_behaves_like 'an unauthorized request'
      end
    end

    describe '#access_token_from_namespace_inheritable' do
      subject { object.access_token_from_namespace_inheritable }

      it 'returns #token_from_namespace_inheritable if it is a personal access token' do
        expect(object).to receive(:token_from_namespace_inheritable).and_return(personal_access_token)
        expect(subject).to be(personal_access_token)
      end

      it 'returns nil if #token_from_namespace_inheritable is not a personal access token' do
        token = double
        expect(object).to receive(:token_from_namespace_inheritable).and_return(token)
        expect(subject).to be(nil)
      end
    end

    describe '#ci_build_from_namespace_inheritable' do
      subject { object.ci_build_from_namespace_inheritable }

      it 'returns #token_from_namespace_inheritable if it is a ci build' do
        expect(object).to receive(:token_from_namespace_inheritable).and_return(ci_build)
        expect(subject).to be(ci_build)
      end

      it 'returns nil if #token_from_namespace_inheritable is not a ci build' do
        expect(object).to receive(:token_from_namespace_inheritable).and_return(personal_access_token)
        expect(subject).to eq(nil)
      end
    end

    describe '#user_from_namespace_inheritable' do
      subject { object.user_from_namespace_inheritable }

      it 'returns #token_from_namespace_inheritable if it is a deploy token' do
        expect(object).to receive(:token_from_namespace_inheritable).and_return(deploy_token)
        expect(subject).to be(deploy_token)
      end

      it 'returns #token_from_namespace_inheritable.user if the token is not a deploy token' do
        user = double
        token = double(user: user)
        expect(object).to receive(:token_from_namespace_inheritable).and_return(token)

        expect(subject).to be(user)
      end

      it 'falls back to #find_user_from_warden if #token_from_namespace_inheritable.user is nil' do
        token = double(user: nil)
        expect(object).to receive(:token_from_namespace_inheritable).and_return(token)
        subject
      end

      it 'falls back to #find_user_from_warden if #token_from_namespace_inheritable is nil' do
        expect(object).to receive(:token_from_namespace_inheritable).and_return(nil)
        subject
      end
    end
  end
end
