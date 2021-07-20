# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Create do
  let_it_be(:parent) { create(:project) }

  let(:project_path) { parent.full_path }
  let(:params) do
    {
      project_path: project_path,
      name: name
    }
  end

  it_behaves_like 'boards create mutation'
end
