# frozen_string_literal: true

require 'spec_helper'

require_relative '../support/stub_member_access_level'

RSpec.describe StubMemberAccessLevel, feature_category: :system_access do
  include described_class

  describe 'stub_member_access_level' do
    shared_examples 'access level stubs' do
      let(:guests) { build_stubbed_list(:user, 2) }
      let(:maintainer) { build_stubbed(:user) }
      let(:no_access) { build_stubbed(:user) }

      it 'stubs max member access level per user' do
        stub_member_access_level(object, maintainer: maintainer, guest: guests)

        # Ensure that multple calls are allowed
        2.times do
          expect(access_level_for(maintainer)).to eq(Gitlab::Access::MAINTAINER)
          expect(access_level_for(guests.first)).to eq(Gitlab::Access::GUEST)
          expect(access_level_for(guests.last)).to eq(Gitlab::Access::GUEST)

          # Partially stub so we expect a mock error.
          expect { access_level_for(no_access) }.to raise_error(RSpec::Mocks::MockExpectationError)
        end
      end

      it 'fails for unstubbed access' do
        expect(access_level_for(no_access)).to eq(Gitlab::Access::NO_ACCESS)
      end

      it 'fails for invalid access level' do
        expect { stub_member_access_level(object, unknown: :anything) }
          .to raise_error(ArgumentError, "Invalid access level :unknown")
      end
    end

    context 'with project' do
      let(:object) { build_stubbed(:project) }

      it_behaves_like 'access level stubs' do
        def access_level_for(user)
          object.team.max_member_access(user.id)
        end
      end
    end

    context 'with group' do
      let(:object) { build_stubbed(:group) }

      it_behaves_like 'access level stubs' do
        def access_level_for(user)
          object.max_member_access_for_user(user)
        end
      end
    end

    context 'with unsupported object' do
      let(:object) { :a_symbol }

      it 'raises an error' do
        expect { stub_member_access_level(object) }
          .to raise_error(ArgumentError, "Stubbing member access level unsupported for :a_symbol (Symbol)")
      end
    end
  end
end
