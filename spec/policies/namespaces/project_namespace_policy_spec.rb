# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProjectNamespacePolicy do
  subject { described_class.new(current_user, namespace) }

  it_behaves_like 'checks timelog categories permissions' do
    let(:project) { create(:project) }
    let(:namespace) { project.project_namespace }
    let(:users_container) { project }
  end
end
