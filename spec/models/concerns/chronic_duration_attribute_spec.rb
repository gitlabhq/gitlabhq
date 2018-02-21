require 'spec_helper'

shared_examples 'ChronicDurationAttribute' do
  describe 'dynamically defined methods' do
    it { expect(subject.class).to be_public_method_defined(virtual_field) }
    it { expect(subject.class).to be_public_method_defined("#{virtual_field}=") }

    it 'parses chronic duration input' do
      subject.send("#{virtual_field}=", "10m")

      expect(subject.send(source_field)).to eq(600)
    end

    it 'outputs chronic duration formated value' do
      subject.send("#{source_field}=", 120)

      expect(subject.send(virtual_field)).to eq('2m')
    end
  end
end

describe 'ChronicDurationAttribute' do
  let(:source_field) { :maximum_job_timeout }
  let(:virtual_field) { :maximum_job_timeout_user_readable }
  subject { Ci::Runner.new }

  it_behaves_like 'ChronicDurationAttribute'
end
