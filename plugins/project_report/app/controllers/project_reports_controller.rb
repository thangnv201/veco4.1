class ProjectReportsController < ApplicationController

  before_action :find_project
  $kq_from_date
  $kq_to_date
  $kh_from_date
  $kh_to_date
  $ten_khoi = 'HKVT'
  $nguoi_bao_cao='TÊN NGƯỜI BÁO CÁO'
  $so_ban = 0
  def index
  end

  def show
    $ten_khoi = params[:ten_khoi]
    $nguoi_bao_cao=params[:nguoi_bao_cao]
    $so_ban = params[:so_ban]
    $kq_from_date = params[:kq_from_date]
    $kq_to_date = params[:kq_to_date]
    $kh_from_date = params[:kh_from_date]
    $kh_to_date = params[:kh_to_date]
    @data = {}
    issues = Issue.where(:project_id => Project.where('lft >= ? and rgt <= ?', @project.lft, @project.rgt).ids)
                 .where(:due_date => $kq_from_date..$kq_to_date)
                 .where(:parent_id => nil).open
                 .order('parent_id')
    issues.each_with_index do |issue, index|
      so_thu_tu = (index + 1).to_s
      @data[issue.id] = {'stt' => so_thu_tu,
                         'subject' => issue.subject,
                         'due_date' => issue.due_date,
                         'status' => issue.status.name,
                         'tien_do' => issue_custom_field(issue, 2),
                         'muc_tieu' => issue_custom_field(issue,2),
                         'assignee' => issue.assigned_to.nil? ? "": issue.assigned_to.login,
                         'ke_hoach' => issue_custom_field(issue,2),
                         'vuong_mac' => issue_custom_field(issue,2)}
      @data = @data.merge(find_child(issue, so_thu_tu))
    end
    issues_vuong_mac = []
    Issue.where(:project_id => Project.where('lft >= ? and rgt <= ?', @project.lft, @project.rgt).ids)
        .where(:due_date => $kq_from_date..$kq_to_date).open
        .order('parent_id').each do |issue|
      if !issue_custom_field(issue, 5).nil? && issue_custom_field(issue, 5) != ""
        issues_vuong_mac << issue
      end
    end
    stt_vuong_mac = 1
    @data_vuong_mac = {}
    issues_vuong_mac.each do |issue|

      if !issue.parent_id.nil?
        if @data_vuong_mac.key?(issue.parent_id)
          parent = @data_vuong_mac[issue.parent_id]
          @data_vuong_mac[issue.id] = {'stt' => parent['stt'] + '.' + (parent['child'] + 1).to_s,
                                       'subject' => issue.subject,
                                       'due_date' => issue.due_date,
                                       'status' => issue.status.name,
                                       'vuong_mac' => issue_custom_field(issue, 5),
                                       'child' => 0}
          @data_vuong_mac[issue.parent_id]['child'] +=1
        end
      end
      if @data_vuong_mac.key?(issue.id)
        next
      end
      @data_vuong_mac[issue.id] = {'stt' => stt_vuong_mac.to_s,
                                   'subject' => issue.subject,
                                   'due_date' => issue.due_date,
                                   'status' => issue.status.name,
                                   'vuong_mac' => issue_custom_field(issue, 5),
                                   'child' => 0}
      stt_vuong_mac+=1
    end

    @data_tuong_lai = {}
    issues = Issue.where(:project_id => Project.where('lft >= ? and rgt <= ?', @project.lft, @project.rgt).ids)
                 .where(:due_date => $kh_from_date..$kh_to_date)
                 .where(:parent_id => nil).open
                 .order('parent_id')
    issues.each_with_index do |issue, index|
      so_thu_tu = (index + 1).to_s
      @data_tuong_lai[issue.id] = {'stt' => so_thu_tu,
                         'subject' => issue.subject,
                         'due_date' => issue.due_date,
                         'status' => issue.status.name,
                         'tien_do' => issue_custom_field(issue, 2),
                         'muc_tieu' => issue_custom_field(issue,2),
                         'assignee' => issue.assigned_to.nil? ? "": issue.assigned_to.login,
                         'ke_hoach' => issue_custom_field(issue,2),
                         'vuong_mac' => issue_custom_field(issue,2)}
      @data_tuong_lai = @data_tuong_lai.merge(find_child(issue, so_thu_tu))
    end
    @test_table = [['s','b','c'],['q','q','q']]
    @data_table = []
    @data_table << ['STT','ID','Subject','Status','Due date','Mục tiêu, kết quả đầu ra','Cập nhật tiến độ','Assignee','Kế hoạch tiếp theo','Vướng mắc /Đề xuất']
    @data.each do |key,value|
      @data_table << [value["stt"],key,value["subject"],value["status"],value["due_date"],value["muc_tieu"],value["tien_do"],value["assignee"],value["ke_hoach"],value["vuong_mac"]]
    end
    @data_tuong_lai_table=[]
    @data_tuong_lai_table << ['STT','ID','Subject','Status','Due date','Mục tiêu, kết quả đầu ra','Cập nhật tiến độ','Assignee','Kế hoạch tiếp theo','Vướng mắc /Đề xuất']
    @data_tuong_lai.each do |key,value|
      @data_tuong_lai_table << [value["stt"],key,value["subject"],value["status"],value["due_date"],value["muc_tieu"],value["tien_do"],value["assignee"],value["ke_hoach"],value["vuong_mac"]]
    end
    byebug
    respond_to do |format|
      format.docx { headers["Content-Disposition"] = "attachment; filename=\"caracal.docx\"" }
    end
  end

  def find_child(issue_parent, stt)
    data = {}
    issue_parent.children.open.each_with_index do |issue, index|
      so_thu_tu = stt + '.' + (index + 1).to_s;
      data[issue.id] = {'stt' => so_thu_tu,
                        'subject' => issue.subject,
                        'due_date' => issue.due_date,
                        'status' => issue.status.name,
                        'tien_do' => issue_custom_field(issue, 2),
                        'muc_tieu' => issue_custom_field(issue,2),
                        'assignee' => issue.assigned_to.nil? ? "": issue.assigned_to.login,
                        'ke_hoach' => issue_custom_field(issue,2),
                        'vuong_mac' => issue_custom_field(issue,2)}
      data = data.merge(find_child(issue, so_thu_tu))
    end
    return data
  end


  def issue_custom_field(issue, id)
    value = ""
    issue.custom_field_values.each do |custom|
      if (custom.custom_field.id == id)
        value = custom.value
        break
      end
    end
    return value
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
end
