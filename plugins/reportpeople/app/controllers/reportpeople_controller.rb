class ReportpeopleController < ApplicationController
  include ReportpeopleHelper
  self.main_menu = false
  $kidanhgia = Project.find(1072).versions.first.id

  def index
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).versions.first.id
    end

    @member = Group.find(1839).users
                  .map { |a| {'id': a.id, 'login': a.login,
                              'donvi': custom_field_user(a.id, 53),
                              'phongban': custom_field_user(a.id, 54),
                              'have_kpi': check_have_kpi(a.id) ? 1 : 0} }
                  .sort_by { |a| [a[:donvi], a[:phongban], a[:have_kpi]] }
    @data = {}
    @member.each do |user|
      @data[user[:donvi]] = {} unless @data.key?(user[:donvi])
      @data[user[:donvi]][user[:phongban]] = [] unless @data[user[:donvi]].key?(user[:phongban])
      @data[user[:donvi]][user[:phongban]] += [{'login': user[:login], 'have_kpi': user[:have_kpi], 'id': user[:id], 'data': ki_danh_gia(user[:id], $kidanhgia)}]
    end
  end

  def ki_danh_gia(user_id, version_id)
    data = {}
    project = Project.find(1072);
    count = project.issues.where(:assigned_to_id => user_id).where.not(:status_id => 35)
                .where(:fixed_version_id => version_id).count
    sum = 0
    project.issues.where(:assigned_to_id => user_id).where.not(:status_id => 35)
        .where(:fixed_version_id => version_id).each do |issue|
      sum += issue_customfield_value(issue, 139).to_i
    end
    data[version_id] = {'count': count, 'sum': sum}
    return data
  end

  def custom_field_user(id, custom_field_id)
    @result = User.find(id).custom_field_values.find { |x| x.custom_field.id == custom_field_id }.value
    if (@result.nil?)
      @result = "";
    end
    return @result
  end


  def issue_customfield_value(issue, custom_field_id)
    value = issue.custom_field_values.find { |x| x.custom_field.id == custom_field_id }.value
    if CustomField.find(custom_field_id).field_format == "enumeration"
      return CustomField.find(custom_field_id).enumerations.where(:id => value).first.name
    end
    return value
  end

end
