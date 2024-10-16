# frozen_string_literal: true

RSpec.shared_context 'for protected ref access' do
  let_it_be(:project) { create(:project, :public, :in_group) }
  let_it_be(:described_factory) { described_class.model_name.singular }
  let_it_be(:protected_ref_name) { described_class.module_parent.model_name.singular }
  let_it_be(:protected_ref_fk) { "#{protected_ref_name}_id" }
  let_it_be(:protected_ref) { create(protected_ref_name, default_access_level: false, project: project) }
end
