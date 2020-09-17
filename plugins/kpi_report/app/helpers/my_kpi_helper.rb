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
end
