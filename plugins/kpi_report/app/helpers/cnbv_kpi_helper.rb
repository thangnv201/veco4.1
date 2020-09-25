module CnbvKpiHelper

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

  def check_ki_lock_status(uid,version)
    if PeopleKiLock.where(lead_id: uid, version_id: version).size != 0
      return PeopleKiLock.where(lead_id: uid, version_id: version).first.status
    else
      return 0
    end
    return 0
  end
end
