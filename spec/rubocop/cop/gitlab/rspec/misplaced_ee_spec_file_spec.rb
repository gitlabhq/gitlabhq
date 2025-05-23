# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../../rubocop/cop/gitlab/rspec/misplaced_ee_spec_file'

RSpec.describe RuboCop::Cop::Gitlab::RSpec::MisplacedEeSpecFile, feature_category: :shared do
  let(:rails_root) { '../../../../../' }

  def full_path(path)
    File.expand_path(File.join(rails_root, path), __dir__)
  end

  before do
    allow(File).to receive(:expand_path).and_call_original
    allow(File).to receive(:expand_path).with('../../../..', anything).and_return(rails_root)
    allow(File).to receive(:exist?).and_call_original
  end

  context 'for an EE spec file with matching EE-only application file' do
    let(:spec_file_path) { full_path('ee/spec/models/my_model_spec.rb') }

    before do
      allow(File).to receive(:exist?).with(File.join(rails_root, 'ee/app/models/my_model.rb')).and_return(true)
    end

    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        describe 'MyModel' do
        end
      RUBY
    end
  end

  context 'for an EE spec file with EE extension file' do
    let(:spec_file_path) { full_path('ee/spec/models/my_model_spec.rb') }
    let(:extension_path) { 'ee/app/models/ee/my_model.rb' }

    before do
      allow(File).to receive(:exist?).with(File.join(rails_root, extension_path)).and_return(true)
    end

    it 'registers an offense' do
      code = "describe 'MyModel'"

      expect_offense(<<~RUBY, spec_file_path, code: code)
        %{code} do
        ^{code} Misplaced EE spec file. This spec should be moved to `ee/spec/models/ee/my_model_spec.rb` since there is an EE extension file: `ee/app/models/ee/my_model.rb`.[...]
        end
      RUBY
    end
  end

  context 'for an EE lib spec file with EE extension file' do
    let(:spec_file_path) { full_path('ee/spec/lib/gitlab/my_lib_spec.rb') }
    let(:extension_path) { 'ee/lib/ee/gitlab/my_lib.rb' }

    before do
      allow(File).to receive(:exist?)
                       .with(File.join(rails_root, extension_path))
                       .and_return(true)
    end

    it 'registers an offense' do
      code = "describe 'Gitlab::MyLib'"
      expect_offense(<<~RUBY, spec_file_path, code: code)
        %{code} do
        ^{code} Misplaced EE spec file. This spec should be moved to `ee/spec/lib/ee/gitlab/my_lib_spec.rb` since there is an EE extension file: `ee/lib/ee/gitlab/my_lib.rb`.[...]
        end
      RUBY
    end
  end

  context 'for an EE lib spec file with matching EE-only lib file' do
    let(:spec_file_path) { full_path('ee/spec/lib/gitlab/my_lib_spec.rb') }

    before do
      allow(File).to receive(:exist?)
                       .with(File.join(rails_root, 'ee/lib/gitlab/my_lib.rb'))
                       .and_return(true)
    end

    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        describe 'Gitlab::MyLib' do
        end
      RUBY
    end
  end

  context 'for an EE spec file with no matching application or extension file' do
    let(:spec_file_path) { full_path('ee/spec/models/my_model_spec.rb') }

    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        describe 'MyModel' do
        end
      RUBY
    end
  end
end
