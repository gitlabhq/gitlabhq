# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::PackagePolicy do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:package) { create(:generic_package, project: project) }

  subject(:policy) { described_class.new(user, package) }

  context 'when the user is part of the project' do
    before do
      project.add_reporter(user)
    end

    it 'allows read_package' do
      expect(policy).to be_allowed(:read_package)
    end
  end

  context 'when the user is not part of the project' do
    it 'disallows read_package for any Package' do
      expect(policy).to be_disallowed(:read_package)
    end
  end
end
