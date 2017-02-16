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

end
