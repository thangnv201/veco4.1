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

  def check_ki_lock_status(uid, version)
    if PeopleKiLock.where(lead_id: uid, version_id: version).size != 0
      return PeopleKiLock.where(lead_id: uid, version_id: version).first.status
    else
      return 0
    end
    return 0
  end

  def permission_cham_ki(uid)
    if Department.where(head_id: uid).count > 0
      return true
    end
    return false
  end

  def permission_chot_ki(uid)
    if Department.where(head_id: uid).where(:ki_confirm => 1).count > 0
      return true
    end
    return false
  end

  def check_ki_lock_status_by_dep(uid, version)
    dids = []
    department_id = Department.where(head_id: uid)
    department_id.each do |dep|
      dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      ids = Department.where("lft > " + lft.to_s + " and rgt < " + rgt.to_s).where.not(ki_confirm: 1)
      ids.each do |obj|
        dids.push(obj.id)
      end
    end
    alluser = User.where(status: 1).where.not(login: User.current.login).select(:id)
    kpi_raking = PeopleInformation.where(department_id: dids, user_id: alluser).order(:user_id)
    users_id = []
    kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    unless users_id.size == 0
      if PeopleKi.where(user_id: users_id, version: version).size == 0
        return 0
      else
        return PeopleKi.where(user_id: users_id, version: version).first.submit_ki
      end
    end
    return 0
  end

  def style_select(uid, version)
    if PeopleKiLock.where(lead_id: uid, version_id: version).size != 0
      status = PeopleKiLock.where(lead_id: uid, version_id: version).first.status
      if status == 0 and status == 2
        return "doing"
      elsif status == 1
        return "danger"
      elsif status == 3
        return "complete"
      end
    else
      return "doing"
    end
    return "doing"
  end

  def class_by_status(status)
    if status == 0
      return "danger"
    elsif status == 3
      return "complete"
    else
      return "doing"
    end
  end
end
