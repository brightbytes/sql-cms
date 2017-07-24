# frozen_string_literal: true
module DataQualityReportSeeder

  extend self

  def seed
    # I could have metaprogrammed this ... but I just want to get it done ...
    [
      DataQualityReport.table_count,
      DataQualityReport.column_value_distribution,
      DataQualityReport.column_non_unique_value_distribution
    ]
  end

end
