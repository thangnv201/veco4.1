class ReportpeopleController < ApplicationController
  include ReportpeopleHelper
  self.main_menu = false
  $kidanhgia = Project.find(1072).default_version.id
  $trangthai = [[1, 'Tạo KPI'], [2, 'Đánh giá KPI'], [3, 'Đánh giá KI']]
  $member

  def index
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version.id
    end
    @department = Department.where(:parent_id => nil)
    # if params.key?("trangthai")
    #   @trangthai = params["trangthai"].to_i
    # else
    #   @trangthai = 1
    # end
    # $member = Group.find(1839).users.where(:status => 1).pluck(:id, :login)
    #               .map { |id, login| [id, login] + tong_ty_trong(id, $kidanhgia) }
    #               .group_by { |a| custom_field_user(a.first, 53) }
    #               .map { |k, v| [k, v.group_by { |b| custom_field_user(b.first, 54) }] }
    # $member1 = User.where(:status => 1).pluck(:id, :login).map { |id, login| [id, login]}.group_by { |a| Person.find(:user_id => a.first).department}
  end

  def get_child_depart
    dep_id = params["dep_id"].to_i
    data = Department.where(:parent_id => dep_id).pluck(:id,:name)
        .map{|a| a<< kpi_department(a[0],$kidanhgia)}

    render json: data
  end

  def get_member
    dep_id = params["dep_id"].to_i
    data = PeopleInformation.joins(:person).where(:department_id => dep_id).where(users:{:status=>1})
                   .map {|a| [a.person.id,a.person.login,count_kpi(a.person.id,$kidanhgia),check_done_kpi(a.person.id,$kidanhgia)]}
    render json: data
  end


  def tong_ty_trong(user_id, version_id)
    ids = Project.find(1072).issues.where(:assigned_to_id => user_id).where.not(:status_id => 35)
              .where(:fixed_version_id => version_id).pluck(:id)
    sum = CustomValue.where(:customized_type => "Issue").where(:custom_field_id => 139).where(:customized_id => ids)
              .pluck(:value).map { |x| x.to_i }.sum
    count = ids.length
    return [sum, count, issue_customfield_value(User.find(user_id), 55)]
  end

  def diem_danh_gia(user_id, version_id)
    ids = Project.find(1072).issues.where(:assigned_to_id => user_id).where.(:status_id => 34)
              .where(:fixed_version_id => version_id).pluck(:id)
    sum = CustomValue.where(:customized_type => "Issue").where(:custom_field_id => 139).where(:customized_id => ids)
              .pluck(:value).map { |x| x.to_i }.sum
    point = PeopleKi.where(:user_id => user_id).where(:version_id => version_id)
  end

  def custom_field_user(id, custom_field_id)
    result = CustomValue.where(:customized_type => "Principal").where(:custom_field_id => custom_field_id)
                 .where(:customized_id => id).pluck(:value)

    if (result.count == 0)
      return "";
    else
      return result.first
    end
  end

  def issue_customfield_value(issue, custom_field_id)
    value = issue.custom_field_values.find { |x| x.custom_field.id == custom_field_id }.value
    if CustomField.find(custom_field_id).field_format == "enumeration"
      return CustomField.find(custom_field_id).enumerations.where(:id => value).first.name
    end
    return value
  end

  def show
    $member
    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"KPI report.xlsx\"" }
    end
  end

end
