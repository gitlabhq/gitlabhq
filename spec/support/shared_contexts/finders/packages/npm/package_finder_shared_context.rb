# frozen_string_literal: true

RSpec.shared_context 'last_of_each_version setup context' do
  let_it_be(:package1) { create(:npm_package, name: 'test', version: '1.2.3', project: project) }
  let_it_be(:package2) { create(:npm_package, name: 'test2', version: '1.2.3', project: project) }

  let(:package_name) { 'test' }
  let(:version) { '1.2.3' }

  before do
    # create a duplicated package without triggering model validation errors
    package2.update_column(:name, 'test')
  end
end
