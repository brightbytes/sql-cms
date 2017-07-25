# frozen_string_literal: true
describe Run::PostgresSchema do

  describe "lifecycle methods" do

    it "should allow listing, creation, and deletion of schemas" do
      run = create(:run)
      schema_name = run.schema_name
      expect(Run.list_schemata).to_not include(schema_name)
      expect(run.schema_exists?).to eq(false)

      run.create_schema
      expect(Run.list_schemata).to include(schema_name)
      expect(run.schema_exists?).to eq(true)

      run.drop_schema
      expect(Run.list_schemata).to_not include(schema_name)
      expect(run.schema_exists?).to eq(false)
    end

  end

  describe "execution methods" do
    it "should have several methods for executing DDL & DML SQL in an extant schema" do
      run = create(:run)
      run.create_schema

      ddl = "CREATE TABLE silly (id serial primary key, stringy character varying NOT NULL)"
      expect { run.execute_in_schema(ddl) }.to_not raise_error


      dml = "INSERT INTO silly (id, stringy) VALUES (DEFAULT, 'FOOBAR!'), (DEFAULT, 'BARFOO!')"
      expect { run.execute_in_schema(dml) }.to_not raise_error

      ar_result = run.select_all_in_schema("SELECT * FROM silly ORDER BY id")
      expect(ar_result.columns).to eq(%w(id stringy))
      expect(ar_result.rows).to eq([[1, 'FOOBAR!'], [2, 'BARFOO!']])

      result = run.select_rows_in_schema("SELECT * FROM silly ORDER BY id")
      expect(result).to eq([[1, 'FOOBAR!'], [2, 'BARFOO!']])

      result = run.select_one_in_schema("SELECT * FROM silly WHERE id = 2")
      expect(result.symbolize_keys).to eq({ id: 2, stringy: 'BARFOO!' })

      result = run.select_values_in_schema("SELECT stringy FROM silly")
      expect(result).to eq(['FOOBAR!', 'BARFOO!'])

      result = run.select_value_in_schema("SELECT count(1) FROM silly")
      expect(result).to eq(2)
    end

    it "should allow Rails Migrations to be run in the schema" do
      run = create(:run)
      run.create_schema
      run.eval_in_schema("create_table(:silly) { |t| t.string :stringy }")
      run.execute_in_schema("INSERT INTO silly (id, stringy) VALUES (DEFAULT, 'FOOBAR!'), (DEFAULT, 'BARFOO!')")
      ar_result = run.select_all_in_schema("SELECT * FROM silly ORDER BY id")
      expect(ar_result.columns).to eq(%w(id stringy))
      expect(ar_result.rows).to eq([[1, 'FOOBAR!'], [2, 'BARFOO!']])
    end
  end

end
