require 'spec_helper'

describe Ci::VariablePresenter do
  include Gitlab::Routing.url_helpers

  let(:project) { create(:project) }
  let(:variable) { create(:ci_variable, project: project) }

  subject(:presenter) do
    described_class.new(variable)
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#initialize' do
    it 'takes a variable and optional params' do
      expect { presenter }.not_to raise_error
    end

    it 'exposes variable' do
      expect(presenter.variable).to eq(variable)
    end

    it 'forwards missing methods to variable' do
      expect(presenter.key).to eq(variable.key)
    end
  end

  describe '#placeholder' do
    subject { described_class.new(variable).placeholder }

    it { is_expected.to eq('PROJECT_VARIABLE') }
  end

  describe '#form_path' do
    subject { described_class.new(variable).form_path }

    it { is_expected.to eq(project_settings_ci_cd_path(project)) }
  end

  describe '#edit_path' do
    subject { described_class.new(variable).edit_path }

    it { is_expected.to eq(project_variables_path(project)) }
  end

  describe '#delete_path' do
    subject { described_class.new(variable).delete_path }

    it { is_expected.to eq(project_variables_path(project)) }
  end
end
