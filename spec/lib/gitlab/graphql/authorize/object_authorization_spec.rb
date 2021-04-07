# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ::Gitlab::Graphql::Authorize::ObjectAuthorization do
  describe '#ok?' do
    subject { described_class.new(%i[go_fast go_slow]) }

    let(:user) { double(:User, id: 10001) }

    let(:policy) do
      Class.new(::DeclarativePolicy::Base) do
        condition(:fast, scope: :subject) { @subject.x >= 10 }
        condition(:slow, scope: :subject) { @subject.y >= 10 }

        rule { fast }.policy do
          enable :go_fast
        end

        rule { slow }.policy do
          enable :go_slow
        end
      end
    end

    before do
      stub_const('Foo', Struct.new(:x, :y))
      stub_const('FooPolicy', policy)
    end

    context 'when there are no abilities' do
      subject { described_class.new([]) }

      it { is_expected.to be_ok(double, double) }
    end

    context 'when no ability should be allowed' do
      let(:object) { Foo.new(0, 0) }

      it { is_expected.not_to be_ok(object, user) }
    end

    context 'when go_fast should be allowed' do
      let(:object) { Foo.new(100, 0) }

      it { is_expected.not_to be_ok(object, user) }
    end

    context 'when go_fast and go_slow should be allowed' do
      let(:object) { Foo.new(100, 100) }

      it { is_expected.to be_ok(object, user) }
    end

    context 'when the object delegates to another subject' do
      def proxy(foo)
        double(:Proxy, declarative_policy_subject: foo)
      end

      it { is_expected.to be_ok(proxy(Foo.new(100, 100)), user) }
      it { is_expected.not_to be_ok(proxy(Foo.new(0, 100)), user) }
    end
  end
end
