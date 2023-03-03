# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/lint/last_keyword_argument'

RSpec.describe RuboCop::Cop::Lint::LastKeywordArgument, :ruby27, feature_category: :shared do
  before do
    described_class.instance_variable_set(:@keyword_warnings, nil)
    allow(Dir).to receive(:glob).and_call_original
    allow(File).to receive(:read).and_call_original
  end

  context 'deprecation files does not exist' do
    before do
      allow(Dir).to receive(:glob).with(described_class::DEPRECATIONS_GLOB).and_return([])
    end

    it 'does not register an offense' do
      expect_no_offenses(<<~SOURCE)
        users.call(params)
      SOURCE
    end
  end

  context 'deprecation files does exist' do
    let(:create_spec_yaml) do
      <<~YAML
      ---
      test_mutations/boards/lists/create#resolve_with_proper_permissions_backlog_list_creates_one_and_only_one_backlog:
      - |
        DEPRECATION WARNING: /Users/tkuah/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/batch-loader-1.4.0/lib/batch_loader/graphql.rb:38: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
        /Users/tkuah/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/batch-loader-1.4.0/lib/batch_loader.rb:26: warning: The called method `batch' is defined here
      test_mutations/boards/lists/create#ready?_raises_an_error_if_required_arguments_are_missing:
      - |
        DEPRECATION WARNING: /Users/tkuah/code/ee-gdk/gitlab/create_service.rb:1: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
        /Users/tkuah/code/ee-gdk/gitlab/user.rb:17: warning: The called method `call' is defined here
      - |
        DEPRECATION WARNING: /Users/tkuah/code/ee-gdk/gitlab/other_warning_type.rb:1: warning: Some other warning type
      YAML
    end

    let(:projects_spec_yaml) do
      <<~YAML
      ---
      test_api/projects_get_/projects_when_unauthenticated_behaves_like_projects_response_returns_an_array_of_projects:
      - |
        DEPRECATION WARNING: /Users/tkuah/code/ee-gdk/gitlab/projects_spec.rb:1: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
        /Users/tkuah/code/ee-gdk/gitlab/lib/gitlab/project.rb:15: warning: The called method `initialize' is defined here
      - |
        DEPRECATION WARNING: /Users/tkuah/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/state_machines-activerecord-0.6.0/lib/state_machines/integrations/active_record.rb:511: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
        /Users/tkuah/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/activerecord-6.0.3.3/lib/active_record/suppressor.rb:43: warning: The called method `save' is defined here
      - |
        DEPRECATION WARNING: /Users/tkuah/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/rack-2.2.3/lib/rack/builder.rb:158: warning: Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
        /Users/tkuah/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/grape-1.4.0/lib/grape/middleware/error.rb:30: warning: The called method `initialize' is defined here
      YAML
    end

    before do
      allow(Dir).to receive(:glob).and_return(['deprecations/service/create_spec.yml', 'deprecations/api/projects_spec.yml'])
      allow(File).to receive(:read).with('deprecations/service/create_spec.yml').and_return(create_spec_yaml)
      allow(File).to receive(:read).with('deprecations/api/projects_spec.yml').and_return(projects_spec_yaml)
    end

    it 'registers an offense for last keyword warning' do
      expect_offense(<<~SOURCE, 'create_service.rb')
        users.call(params)
                   ^^^^^^ Using the last argument as keyword parameters is deprecated
      SOURCE

      expect_correction(<<~SOURCE)
        users.call(**params)
      SOURCE
    end

    it 'does not register an offense for other warning types' do
      expect_no_offenses(<<~SOURCE, 'other_warning_type.rb')
        users.call(params)
      SOURCE
    end

    it 'registers an offense for the new method call' do
      expect_offense(<<~SOURCE, 'projects_spec.rb')
        Project.new(params)
                    ^^^^^^ Using the last argument as keyword parameters is deprecated
      SOURCE

      expect_correction(<<~SOURCE)
        Project.new(**params)
      SOURCE
    end

    it 'registers an offense and corrects by converting hash to kwarg' do
      expect_offense(<<~SOURCE, 'create_service.rb')
        users.call(id, { a: :b, c: :d })
                       ^^^^^^^^^^^^^^^^ Using the last argument as keyword parameters is deprecated
      SOURCE

      expect_correction(<<~SOURCE)
        users.call(id, a: :b, c: :d)
      SOURCE
    end

    it 'registers an offense on the last non-block argument' do
      expect_offense(<<~SOURCE, 'create_service.rb')
        users.call(id, params, &block)
                       ^^^^^^ Using the last argument as keyword parameters is deprecated
      SOURCE

      expect_correction(<<~SOURCE)
        users.call(id, **params, &block)
      SOURCE
    end

    it 'does not register an offense if the only argument is a block argument' do
      expect_no_offenses(<<~SOURCE, 'create_service.rb')
        users.call(&block)
      SOURCE
    end

    it 'registers an offense and corrects by converting splat to double splat' do
      expect_offense(<<~SOURCE, 'create_service.rb')
        users.call(id, *params)
                       ^^^^^^^ Using the last argument as keyword parameters is deprecated
      SOURCE

      expect_correction(<<~SOURCE)
        users.call(id, **params)
      SOURCE
    end

    it 'does not register an offense if already a kwarg', :aggregate_failures do
      expect_no_offenses(<<~SOURCE, 'create_service.rb')
        users.call(**params)
      SOURCE

      expect_no_offenses(<<~SOURCE, 'create_service.rb')
        users.call(id, a: :b, c: :d)
      SOURCE
    end

    it 'does not register an offense if the method name does not match' do
      expect_no_offenses(<<~SOURCE, 'create_service.rb')
        users.process(params)
      SOURCE
    end

    it 'does not register an offense if the line number does not match' do
      expect_no_offenses(<<~SOURCE, 'create_service.rb')
        users.process
        users.call(params)
      SOURCE
    end

    it 'does not register an offense if the filename does not match' do
      expect_no_offenses(<<~SOURCE, 'update_service.rb')
        users.call(params)
      SOURCE
    end

    context 'with Ruby 3.0', :ruby30 do
      it 'does not register an offense with known warning' do
        expect_no_offenses(<<~SOURCE, 'create_service.rb')
          users.call(params)
        SOURCE
      end
    end
  end
end
