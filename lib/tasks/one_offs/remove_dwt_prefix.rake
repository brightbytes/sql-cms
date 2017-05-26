require "#{Rails.root}/lib/tasks/task_helper"

namespace :db do

  include TaskHelper

  task nuke_dwt: :environment do
    Workflow.all.each do |w|
      w.name = w.name.gsub('dwt_', '')
      w.save!
      w.transforms.all.each do |t|
        sql_remove_dwt(t)
        params_remove_dwt(t)
        t.transform_validations.all.each do |tv|
          params_remove_dwt(tv)
        end
      end
      w.workflow_data_quality_reports.all.each do |wdqr|
        params_remove_dwt(wdqr)
      end
    end
    v = Validation.find(12)
    v.name = v.name.gsub('dwt_', '')
    v.sql = v.sql.gsub('dwt_', '')
    v.save!
  end

  def sql_remove_dwt(o)
    o.sql = o.sql.gsub('dwt_', '') if o.sql.present?
    o.name = o.name.gsub('dwt_', '')
    o.save!
  end

  def params_remove_dwt(o)
    if o.params.present?
      o.params = o.params.map do |k, v|
        [k, v.is_a?(String) ? v.gsub('dwt_', '') : v]
      end.to_h
      o.save!
    end
  end

end
