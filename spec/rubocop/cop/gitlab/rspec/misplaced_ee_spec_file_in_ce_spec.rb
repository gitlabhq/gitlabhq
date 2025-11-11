# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../../rubocop/cop/gitlab/rspec/misplaced_ee_spec_file_in_ce'

RSpec.describe RuboCop::Cop::Gitlab::RSpec::MisplacedEeSpecFileInCe, feature_category: :tooling do
  let(:rails_root) { '../../../../../' }

  def full_path(path)
    File.expand_path(File.join(rails_root, path), __dir__)
  end

  shared_context 'with File setup' do |ce_path_exists:, ee_path_exists:|
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(ce_class_path).and_return(ce_path_exists)
      allow(File).to receive(:exist?).with(ee_class_path).and_return(ee_path_exists)
    end
  end

  context 'when spec is in CE and tests an EE-only class' do
    let(:spec_file_path) { full_path('spec/lib/api/helpers/audit_events_cursor_helper_spec.rb') }
    let(:ce_class_path) { full_path('lib/api/helpers/audit_events_cursor_helper.rb') }
    let(:ee_class_path) { full_path('ee/lib/api/helpers/audit_events_cursor_helper.rb') }

    include_context 'with File setup', ce_path_exists: false, ee_path_exists: true

    it 'registers an offense' do
      expect_offense(<<~RUBY, spec_file_path)
        RSpec.describe API::Helpers::AuditEventsCursorHelper do
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This spec tests an EE-only class and should be moved to `ee/spec/lib/api/helpers/audit_events_cursor_helper_spec.rb`. The class `API::Helpers::AuditEventsCursorHelper` is only defined in `ee/lib/api/helpers/audit_events_cursor_helper.rb`. See https://docs.gitlab.com/development/ee_features/#separation-of-ee-code-in-the-backend.
          it 'does something' do
          end
        end
      RUBY
    end
  end

  context 'when spec is in CE and tests a CE class' do
    let(:spec_file_path) { full_path('spec/models/user_spec.rb') }
    let(:ce_class_path) { full_path('app/models/user.rb') }
    let(:ee_class_path) { full_path('ee/app/models/user.rb') }

    include_context 'with File setup', ce_path_exists: true, ee_path_exists: true

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        RSpec.describe User do
          it 'does something' do
          end
        end
      RUBY
    end
  end

  context 'when spec is already in EE' do
    let(:spec_file_path) { full_path('ee/spec/lib/api/helpers/audit_events_cursor_helper_spec.rb') }

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        RSpec.describe API::Helpers::AuditEventsCursorHelper do
          it 'does something' do
          end
        end
      RUBY
    end
  end

  context 'when spec is for a service' do
    let(:spec_file_path) { full_path('spec/services/my_ee_service_spec.rb') }
    let(:ce_class_path) { full_path('app/services/my_ee_service.rb') }
    let(:ee_class_path) { full_path('ee/app/services/my_ee_service.rb') }

    include_context 'with File setup', ce_path_exists: false, ee_path_exists: true

    it 'registers an offense' do
      expect_offense(<<~RUBY, spec_file_path)
        RSpec.describe MyEeService do
                       ^^^^^^^^^^^ This spec tests an EE-only class and should be moved to `ee/spec/services/my_ee_service_spec.rb`. The class `MyEeService` is only defined in `ee/app/services/my_ee_service.rb`. See https://docs.gitlab.com/development/ee_features/#separation-of-ee-code-in-the-backend.
          it 'does something' do
          end
        end
      RUBY
    end
  end

  context 'when spec is for a model' do
    let(:spec_file_path) { full_path('spec/models/ee_model_spec.rb') }
    let(:ce_class_path) { full_path('app/models/ee_model.rb') }
    let(:ee_class_path) { full_path('ee/app/models/ee_model.rb') }

    include_context 'with File setup', ce_path_exists: false, ee_path_exists: true

    it 'registers an offense' do
      expect_offense(<<~RUBY, spec_file_path)
        RSpec.describe EeModel do
                       ^^^^^^^ This spec tests an EE-only class and should be moved to `ee/spec/models/ee_model_spec.rb`. The class `EeModel` is only defined in `ee/app/models/ee_model.rb`. See https://docs.gitlab.com/development/ee_features/#separation-of-ee-code-in-the-backend.
          it 'does something' do
          end
        end
      RUBY
    end
  end

  context 'when class exists in both CE and EE' do
    let(:spec_file_path) { full_path('spec/models/project_spec.rb') }
    let(:ce_class_path) { full_path('app/models/project.rb') }
    let(:ee_class_path) { full_path('ee/app/models/project.rb') }

    include_context 'with File setup', ce_path_exists: true, ee_path_exists: true

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        RSpec.describe Project do
          it 'does something' do
          end
        end
      RUBY
    end
  end

  context 'when spec uses described_class' do
    let(:spec_file_path) { full_path('spec/models/ee_model_spec.rb') }

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        RSpec.describe described_class do
          it 'does something' do
          end
        end
      RUBY
    end
  end

  context 'when spec is for a controller' do
    let(:spec_file_path) { full_path('spec/controllers/ee_controller_spec.rb') }
    let(:ce_class_path) { full_path('app/controllers/ee_controller.rb') }
    let(:ee_class_path) { full_path('ee/app/controllers/ee_controller.rb') }

    include_context 'with File setup', ce_path_exists: false, ee_path_exists: true

    it 'registers an offense' do
      expect_offense(<<~RUBY, spec_file_path)
        RSpec.describe EeController do
                       ^^^^^^^^^^^^ This spec tests an EE-only class and should be moved to `ee/spec/controllers/ee_controller_spec.rb`. The class `EeController` is only defined in `ee/app/controllers/ee_controller.rb`. See https://docs.gitlab.com/development/ee_features/#separation-of-ee-code-in-the-backend.
          it 'does something' do
          end
        end
      RUBY
    end
  end
end
