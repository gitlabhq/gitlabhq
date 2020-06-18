# frozen_string_literal: true

require 'spec_helper'

describe Releases::SourcePolicy do
  using RSpec::Parameterized::TableSyntax

  let(:policy) { described_class.new(user, source) }

  let_it_be(:public_user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:release) { create(:release, project: project) }
  let(:source) { release.sources.first }

  shared_examples 'source code access' do
    it "allows access a release's source code" do
      expect(policy).to be_allowed(:read_release_sources)
    end
  end

  shared_examples 'no source code access' do
    it "does not allow access a release's source code" do
      expect(policy).to be_disallowed(:read_release_sources)
    end
  end

  context 'a private project' do
    let_it_be(:project) { create(:project, :private) }

    context 'accessed by a public user' do
      let(:user) { public_user }

      it_behaves_like 'no source code access'
    end

    context 'accessed by a user with Guest permissions' do
      let(:user) { guest }

      before do
        project.add_guest(user)
      end

      it_behaves_like 'no source code access'
    end

    context 'accessed by a user with Reporter permissions' do
      let(:user) { reporter }

      before do
        project.add_reporter(user)
      end

      it_behaves_like 'source code access'
    end
  end

  context 'a public project' do
    let_it_be(:project) { create(:project, :public) }

    context 'accessed by a public user' do
      let(:user) { public_user }

      it_behaves_like 'source code access'
    end

    context 'accessed by a user with Guest permissions' do
      let(:user) { guest }

      before do
        project.add_guest(user)
      end

      it_behaves_like 'source code access'
    end

    context 'accessed by a user with Reporter permissions' do
      let(:user) { reporter }

      before do
        project.add_reporter(user)
      end

      it_behaves_like 'source code access'
    end
  end
end
