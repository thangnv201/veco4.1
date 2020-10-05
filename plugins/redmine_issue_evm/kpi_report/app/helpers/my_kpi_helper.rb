module MyKpiHelper

  def issue_customfield_value(issue, custom_field_id)
    custom_field = issue.custom_field_values.find { |x| x.custom_field.id == custom_field_id }
    if !custom_field.nil?
      value = custom_field.value
    else
      return ""
    end
    if CustomField.find(custom_field_id).field_format == "date"
      begin
        return Date.parse(custom_field.value).strftime('%d/%m/%Y')
      rescue Exception => e
        return ""
      end
    end
    if CustomField.find(custom_field_id).field_format == "enumeration"
      object = CustomField.find(custom_field_id).enumerations.where(:id => value).first
      if object.nil?
        return ""
      else
        return object.name
      end
    end
    return value
  end

  def percent_cbnv(user_id, version)
    total_kpi = Project.find(1072).issues.where(:author_id => User.current.id)
                    .where(:fixed_version_id => version)
                    .where(:assigned_to => user_id)
                    .where.not(:status_id => 35).count
    count_da_danh_gia = Project.find(1072).issues.where(:author_id => User.current.id)
                            .where(:fixed_version_id => version)
                            .where(:assigned_to => user_id)
                            .where(:status_id => [29, 32, 33]).count
    percent = 100 - (count_da_danh_gia * 100.0) / total_kpi
    result = case
             when percent == 0
               "danger"
             when percent < 100 && percent > 0
               "doing"
             when percent == 100
               "complete"
             end
    result
  end
end
