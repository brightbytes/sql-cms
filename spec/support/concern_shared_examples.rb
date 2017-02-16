shared_examples 'yaml helper methods' do

  it "should provide methods to get and set the #params JSON attribute using YAML" do
    yaml = <<-YAML.strip_heredoc
      foo: bar
      whatever: dude
    YAML
    subject.params_yaml = yaml
    expect(subject.params).to eq({ 'foo' => 'bar', 'whatever' => 'dude' })
    expect(subject.params_yaml).to eq("---\n" << yaml)
  end

  it "should be rendered invalid upon invalid yaml being set" do
    expect(subject).to be_valid
    subject.params_yaml = "foo: bar: :dude"
    expect(subject).to_not be_valid
  end

  it "should provide instance- and class-level interpolation methods" do
    subject.params = { foo: :bar, whatever: :dude }
    sql = "SELECT :foo FROM :whatever"
    if subject.is_a?(TransformValidation)
      subject.validation.sql = sql
    else
      subject.sql = sql
    end
    expect(subject.interpolated_sql).to eq("SELECT bar FROM dude")

    expect(subject.class.interpolate(sql: sql, params: subject.params)).to eq("SELECT bar FROM dude")
  end

end
