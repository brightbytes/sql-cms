# frozen_string_literal: true
describe Run::PostgresSchema do

  describe "lifecycle methods" do

    it "should allow listing, creation, and deletion of schemas" do
      run = create(:run)
      schema_name = run.schema_name
      expect(Run.list_schemas).to_not include(schema_name)
      expect(run.schema_exists?).to eq(false)

      run.create_schema
      expect(Run.list_schemas).to include(schema_name)
      expect(run.schema_exists?).to eq(true)

      run.drop_schema
      expect(Run.list_schemas).to_not include(schema_name)
      expect(run.schema_exists?).to eq(false)
    end

  end

  describe "execution methods" do
    it "should have different methods for executing DDL & DML SQL in an extant schema" do
      run = create(:run)
      run.create_schema

      ddl = "CREATE TABLE silly (id serial primary key, stringy character varying NOT NULL)"
      expect { run.execute_in_schema(ddl) }.to_not raise_error


      dml = "INSERT INTO silly (id, stringy) VALUES (DEFAULT, 'FOOBAR!'), (DEFAULT, 'BARFOO!')"
      expect { run.execute_in_schema(dml) }.to_not raise_error

      ar_result = run.select_all_in_schema("SELECT * FROM silly ORDER BY id")
      expect(ar_result.columns).to eq(%w(id stringy))
      expect(ar_result.rows).to eq([[1, 'FOOBAR!'], [2, 'BARFOO!']])
    end
  end

end
