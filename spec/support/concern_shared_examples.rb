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

  # This test is extraordinarily silly (i.e. quite pathetic) - it should really be separate specs in the parent files.  Bah.
  it "should provide instance- and class-level interpolation methods" do
    subject.params = { foo: :bar, whatever: [:check, :this, :out] }
    name = "Silly :foo, :whatever, dude"
    sql = "SELECT :foo FROM (:whatever)"
    if subject.is_a?(TransformValidation)
      subject.validation.sql = sql
      subject.validation.name = name
    elsif subject.is_a?(WorkflowDataQualityReport)
      subject.data_quality_report.sql = sql
      subject.data_quality_report.name = name
    else
      subject.sql = sql
      subject.name = name
    end
    expect(subject.interpolated_sql).to eq("SELECT bar FROM ('check', 'this', 'out')")
    expect(subject.interpolated_name).to eq("Silly bar, check, this, out, dude")

    expect(subject.class.interpolate(string: sql, params: subject.params, quote_arrays: true)).to eq("SELECT bar FROM ('check', 'this', 'out')")
    expect(subject.class.interpolate(string: name, params: subject.params, quote_arrays: false)).to eq("Silly bar, check, this, out, dude")

    # Transforms are the only subject where params can be empty
    if subject.is_a?(Transform)
      subject.params = {}
      expect(subject.interpolated_sql).to eq(sql)
      expect(subject.interpolated_name).to eq(name)
    end
  end

end
