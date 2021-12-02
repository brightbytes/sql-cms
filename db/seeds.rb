dputs "Seeding the DB ..."

# PaperTrail.enabled = false

UserSeeder.seed
CustomerSeeder.seed
ValidationSeeder.seed
DataQualityReportSeeder.seed

begin
  WorkflowSeeder.seed
rescue
  dputs "If the following error concerns a bucket name being absent, you need set up your `.env` file, per the README"
  raise
end

# Uncomment for more-rapid dev ...
# WorkflowSeeder.reseed
