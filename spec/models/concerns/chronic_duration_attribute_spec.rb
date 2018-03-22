require 'spec_helper'

shared_examples 'ChronicDurationAttribute reader' do
  it 'contains dynamically created reader method' do
    expect(subject.class).to be_public_method_defined(virtual_field)
  end

  it 'outputs chronic duration formatted value' do
    subject.send("#{source_field}=", 120)

    expect(subject.send(virtual_field)).to eq('2m')
  end

  context 'when value is set to nil' do
    it 'outputs nil' do
      subject.send("#{source_field}=", nil)

      expect(subject.send(virtual_field)).to be_nil
    end
  end
end

shared_examples 'ChronicDurationAttribute writer' do
  it 'contains dynamically created writer method' do
    expect(subject.class).to be_public_method_defined("#{virtual_field}=")
  end

  before do
    subject.send("#{virtual_field}=", '10m')
  end

  it 'parses chronic duration input' do
    expect(subject.send(source_field)).to eq(600)
  end

  it 'passes validation' do
    expect(subject.valid?).to be_truthy
  end

  context 'when negative input is used' do
    before do
      subject.send("#{source_field}=", 3600)
    end

    it "doesn't raise exception" do
      expect { subject.send("#{virtual_field}=", '-10m') }.not_to raise_error(ChronicDuration::DurationParseError)
    end

    it "doesn't change value" do
      expect { subject.send("#{virtual_field}=", '-10m') }.not_to change { subject.send(source_field) }
    end

    it "doesn't pass validation" do
      subject.send("#{virtual_field}=", '-10m')

      expect(subject.valid?).to be_falsey
      expect(subject.errors&.messages).to include(virtual_field => ['is not a correct duration'])
    end
  end

  context 'when empty input is used' do
    before do
      subject.send("#{virtual_field}=", '')
    end

    it 'writes nil' do
      expect(subject.send(source_field)).to be_nil
    end

    it 'passes validation' do
      expect(subject.valid?).to be_truthy
    end
  end

  context 'when nil input is used' do
    before do
      subject.send("#{virtual_field}=", nil)
    end

    it 'writes nil' do
      expect(subject.send(source_field)).to be_nil
    end

    it 'passes validation' do
      expect(subject.valid?).to be_truthy
    end

    it "doesn't raise exception" do
      expect { subject.send("#{virtual_field}=", nil) }.not_to raise_error(NoMethodError)
    end
  end
end

describe 'ChronicDurationAttribute' do
  let(:source_field) {:maximum_timeout}
  let(:virtual_field) {:maximum_timeout_human_readable}

  subject { Ci::Runner.new }

  it_behaves_like 'ChronicDurationAttribute reader'
  it_behaves_like 'ChronicDurationAttribute writer'
end

describe 'ChronicDurationAttribute - reader' do
  let(:source_field) {:timeout}
  let(:virtual_field) {:timeout_human_readable}

  subject {Ci::BuildMetadata.new}

  it "doesn't contain dynamically created writer method" do
    expect(subject.class).not_to be_public_method_defined("#{virtual_field}=")
  end

  it_behaves_like 'ChronicDurationAttribute reader'
end
