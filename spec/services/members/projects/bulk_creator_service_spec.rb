# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Projects::BulkCreatorService do
  it_behaves_like 'bulk member creation' do
    let_it_be(:source, reload: true) { create(:project, :public) }
    let_it_be(:member_type) { ProjectMember }
  end
end
