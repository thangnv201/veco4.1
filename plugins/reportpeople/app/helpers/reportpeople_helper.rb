module ReportpeopleHelper

  def check_have_kpi(user_id)
    if Project.find(1072).issues.where(:assigned_to_id => user_id).where(:fixed_version_id => $kidanhgia).length > 0
      return true
    else
      return false
    end
  end
end
