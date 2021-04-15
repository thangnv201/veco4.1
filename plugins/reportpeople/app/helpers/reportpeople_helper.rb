module ReportpeopleHelper

  def check_have_kpi(user_id)
    if Project.find(1072).issues.where(:assigned_to_id => user_id).where(:fixed_version_id => $kidanhgia).length > 0
      return true
    else
      return false
    end
  end

  def haschild(dep_id)
    if Department.where(:parent_id => dep_id).count == 0
      return false
    else
      return true
    end
  end

  def kpi_department(dep_id, version_id)
    user_ids = PeopleInformation.joins(:person).where(:department_id => dep_id).where(users:{:status=>1}).pluck(:user_id)
    total = user_ids.count
    temp = 0
    user_ids.each do |user_id|
      if check_done_kpi(user_id, version_id) == 100
        temp = temp + 1
      end
    end
    return temp.to_s + "/" + total.to_s

  end

  def count_kpi(user_id, version_id)
    return Project.find(1072).issues.where.not(:status_id => 35).where(:tracker_id => [39, 40, 41]).where(:assigned_to_id => user_id).where(:fixed_version_id => version_id).count
  end

  def check_done_kpi(user_id, version_id)
    titrong = 0
    Project.find(1072).issues.where.not(:status_id => 35).where(:tracker_id => [39, 40, 41])
        .where(:assigned_to_id => user_id).where(:fixed_version_id => version_id)
        .each do |issue|
      titrong += issue_customfield_value(issue, 139).to_i
    end
    return titrong

  end
  $list_member_dont_have_kpi =[]
  def count_user_dont_have_kpi(version_id)
    temp=0
    $list_member_dont_have_kpi.clear
    Group.find(1839).users.each do |u|
      if check_done_kpi(u.id,version_id) <100
        temp = temp+1
        $list_member_dont_have_kpi << u.id
      end
    end
    return temp
  end

  def issue_customfield_value(issue, custom_field_id)
    value = issue.custom_field_values.find { |x| x.custom_field.id == custom_field_id }.value
    if CustomField.find(custom_field_id).field_format == "enumeration"
      return CustomField.find(custom_field_id).enumerations.where(:id => value).first.name
    end
    return value
  end
end
