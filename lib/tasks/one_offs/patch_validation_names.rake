namespace :support do

  # Nuke this task and retrofit the seeded Validations once this is run in prod

  OLD_TO_NEW_MAP = {
    'Field Value IS NOT NULL' => 'Column :table_name.:column_name IS NOT NULL',
    'String Field Value is Present' => 'Column :table_name.:column_name is Present',
    'Field Value is Unique' => 'Column :table_name.:column_name is Unique',
    'Field Value is always a valid FK-Reference' => 'Column :table_name.:column_name is a Valid FK',
    'Field Value is included in a Set of Values' => 'Column :table_name.:column_name is Included in :allowed_values',
    'Field Value is an Integer' => 'Column :table_name.:column_name is an Integer',
    'Field Value is an Integer or one of the additional values' => 'Column :table_name.:column_name is an Integer or :extras',
    'Field Value Greater Than' => 'Column :table_name.:column_name is Greater Than :value',
    'Field Value Less Than' => 'Column :table_name.:column_name is Less Than :value',
    "Field Ranges don't overlap" => "Table :table_name's Columns :low_column_name & :high_column_name Denote a Non-Overlapping Range"
  }

  task patch_validations: :environment do
    OLD_TO_NEW_MAP.each_pair do |old_val, new_val|
      Validation.connection.update("UPDATE validations SET immutable = FALSE")
      validation = Validation.find_by(name: old_val)
      validation.name = new_val
      validation.immutable = true
      validation.save!
    end
  end

end
