module TaskReportsHelper

  CORPORATION_PROJECT_ID = 297

  def check_clicked_search_button(params)
    return false unless params[:project_report].present?
    return false unless params[:time_reports].present?
    return false unless params[:time_reports].present?
    return false unless params[:time_reports][:start_date].present?
    return false unless params[:time_reports][:due_date].present?
    true
  end

  def check_searched_type(start_date, due_date)
    searched_type = {}
    checked_start_date = start_date.at_beginning_of_month
    checked_due_date = start_date.end_of_month
    if checked_start_date == start_date and checked_due_date == due_date
      searched_type[:full_month_search_type] = true
    else
      searched_type[:full_month_search_type] = false
    end
    searched_type[:daysInMonth] = (start_date..due_date).select{|day| day.wday < 6 && day.wday > 0}.count
    searched_type
  end

  def get_all_child_project(parent_project)
    project_visible = []
    person = User.current
    memberships = person.memberships.preload(:roles, :project).where(Project.visible_condition(person)).to_a
    memberships_by_project = memberships.group_by(&:project)
    Project.project_tree(memberships_by_project.keys, :init_level => true) do |project, level|
      if project.lft >= parent_project.lft and project.rgt <= parent_project.rgt and project.status == 1
        project_visible.push({:project => project,:level => level})
      end
    end
    project_visible.sort { |x, y| x[:project].lft <=> y[:project].lft}
    project_visible
  end

  def retrieve_project_select_tag(selected_id)
    parent_project = Project.find(CORPORATION_PROJECT_ID)
    project_visible = get_all_child_project(parent_project)

    s = ''.html_safe
    project_visible.each do |project_and_level|
      project = project_and_level[:project]
      level = project_and_level[:level]

      name_prefix = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      tag_options = {:value => project.id}
      if selected_id == project.id
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      s << content_tag('option', name_prefix + h(project), tag_options)
    end

    content_tag('select', s.html_safe, :name => 'project_report', :id => 'project_reports')
  end

  def dump_export_report_data (type, header, parent_project_name, start_date, due_date, data)
    export_data = {}
    export_data["type"] = type
    export_data["header"] = header
    export_data["parent_project_name"] = parent_project_name
    export_data["start_date"] = start_date
    export_data["due_date"] = due_date
    export_data["data"] = data
    JSON.dump(export_data)
  end

  def load_export_report_data (params)
    json_data = params[:export_reports][:data]
    load_data = JSON.load(json_data)
    export_data = {}
    export_data[:type] = load_data["type"]
    export_data[:header] = load_data["header"]
    export_data[:parent_project_name] = load_data["parent_project_name"]
    export_data[:start_date] = load_data["start_date"]
    export_data[:due_date] = load_data["due_date"]
    export_data[:data] = load_data["data"]
    export_data
  end

  def link_to_user_from_user_id (user_id)
    user = User.find(user_id)
    link_to_user_login(user)
  end

  def link_to_project_from_project_id (project_id)
    project = Project.find(project_id)
    link_to_project(project)
  end


  def retrieve_department_tree
    department_list = []
    department_list.push(["Tất cả phòng ban", 0])
    indent = ""

    Department.where('parent_id is null').order(:lft).each do |department|
      next if department.name.include? "Ban giám đốc"
      department_list.push([indent + department.name, department.id])
      department_list += get_child_department(department, indent) unless department.all_child.count == 0
    end

    department_list
  end

  def get_child_department(department, indent)
    department_list = []
    indent += ">>>"
    department.all_child.order(:lft).each do |department_child|
      next if department_child.name.include? "Ban giám đốc"
      department_list.push([indent + department_child.name, department_child.id])
      department_list += get_child_department(department_child, indent) unless department_child.all_child.count == 0
    end

    department_list
  end

  def retrieve_people_all_department
    people_list = []
    Department.where('parent_id is null').each do |department|
      people_list += department.people_of_branch_department.to_a
    end
    people_list
  end

  def find_max_level(all_project_level_array)
    max_level = 0
    all_project_level_array.each do |project_level|
      level = project_level[:level]
      max_level = level if level > max_level
    end
    max_level
  end

  def get_ancestral_project(project, project_id_list)
    ancestral_project_id = -1
    until project.parent_id.nil? do
      project = project.parent
      project_id = project.id
      if project_id_list.index(project_id)
        ancestral_project_id = project_id
        break
      end
    end

    ancestral_project_id
  end

  def retrieve_people_of_project_hash(all_project_level_array)
    role_list = get_roles

    project_member_hash = {}

    project_id_list = all_project_level_array.map { |project_level| project_level[:project].id }

    #  find max level
    max_level = find_max_level(all_project_level_array)


    (0..max_level).each do |level|
      all_project_level_array.each do |project_level|
        p = project_level[:project]
        l = project_level[:level]
        if l == (max_level - level)
          project_id = p.id
          project_member_hash[project_id] = [] unless project_member_hash.key?(project_id)
          project_member_hash[project_id] += retrieve_user_id_list_with_roles(p, project_member_hash[project_id], role_list)
          project_member_hash[project_id] = project_member_hash[project_id].uniq

          ancestral_project_id = get_ancestral_project(p, project_id_list)
          if ancestral_project_id != -1
            project_member_hash[ancestral_project_id] = [] unless project_member_hash.key?(ancestral_project_id)
            project_member_hash[ancestral_project_id] += project_member_hash[project_id]
          end
        end
      end
    end

    project_member_hash
  end

  def retrieve_project_people_hash(parent_project)

    child_project_name_id_list = []
    child_project_id_list = []
    people_id_list = []
    all_project_level_array = get_all_child_project(parent_project)

    if all_project_level_array.size == 1
      has_child = false
    else
      has_child = true
      # Find level of parent project
      pl = all_project_level_array.find { |project_level| project_level[:project].id = parent_project.id }
      parent_project_level = pl[:level]

      all_project_level_array.each do |project_level|
        level = project_level[:level]
        if level == (parent_project_level + 1)
          project = project_level[:project]
          child_project_name_id_list.push([project.name, project.id])
          child_project_id_list.push(project.id)
        end
      end
    end


    project_member_hash = retrieve_people_of_project_hash(all_project_level_array)
    project_member_hash.each do |key, value|
      project_member_hash.delete(key) if child_project_id_list.index(key).nil?
      people_id_list += value
    end


    result = {}
    result[:has_child] = has_child
    result[:name_id_project_list] = child_project_name_id_list
    result[:project_member] = project_member_hash
    result[:people_id_list] = people_id_list.uniq
    result
  end

  def retrieve_declared_people_hash(people_id_list, start_date, due_date, is_full_month)

    people_list = people_id_list.map {|id| Person.find(id)}
    people_list.delete_if {|person| check_undeclared_person(person, start_date, due_date)}

    declared_people_list = {}

    people_list.each do |person|
      person_id = person.id
      declared_people_list[person_id] = person.calculate_efforts_time(start_date, due_date, is_full_month)
    end
    declared_people_list
  end


  def retrieve_user_id_list_with_roles(project, id_list, role_list)
    current_id_list = project.users.ids
    id_list_check = current_id_list - id_list

    member_list = Member.joins(:roles)
                      .where("#{Role.table_name}.name" => role_list)
                      .where(:project_id => project.id)
                      .where(:user_id => id_list_check)

    member_list.map(&:user_id)
  end


  def get_roles
    role_list = []
    begin
      xml_config_file = File.open("files/Config/config.xml")
      data = Hash.from_xml(xml_config_file)

      role_list = data["config"]["task_reports"]["role_list"]["role"]

      xml_config_file.close unless xml_config_file.closed?

    rescue Exception => ex
      Rails.logger.info "Cannot read config file to get role list"
    end

    role_list
  end

  def retrieve_task_people_list(people_list, month)
    date = month.to_date
    begin_of_month = date.at_beginning_of_month
    end_of_month = date.end_of_month

    people_list.delete_if {|person| check_undeclared_person(person, begin_of_month, end_of_month)}

    declared_people_list = {}

    people_list.each do |person|
      person_id = person.id
      declared_people_list[person_id] = person.efforts_time(begin_of_month, end_of_month)
    end

    declared_people_list
  end

  def calculate_task_department_people(department_list, department_name_list, daysInMonth, declared_people_hash)
    total_100_percent_hours = daysInMonth.to_i * 8
    total_50_percent_hours = total_100_percent_hours * 0.5
    total_70_percent_hours = total_100_percent_hours * 0.7

    percent_point = [total_50_percent_hours, total_70_percent_hours, total_100_percent_hours]

    estimated_result = calculate_tasked_people(department_list,
                                               department_name_list,
                                               declared_people_hash,
                                               percent_point,
                                               :estimated_hours)

    actual_result = calculate_tasked_people(department_list,
                                            department_name_list,
                                            declared_people_hash,
                                            percent_point,
                                            :actual_hours)

    result = {}
    result[:estimate] = estimated_result
    result[:actual] = actual_result

    result
  end

  def calculate_task_project_people(child_project_list, project_name_id, daysInMonth, declared_people_hash, is_full_month)
    total_100_percent_hours = daysInMonth.to_i * 8
    total_50_percent_hours = total_100_percent_hours * 0.5
    total_70_percent_hours = total_100_percent_hours * 0.7

    percent_point = [total_50_percent_hours, total_70_percent_hours, total_100_percent_hours]

    actual_result = calculate_tasked_project_people(child_project_list,
                                                    project_name_id,
                                                    declared_people_hash,
                                                    percent_point,
                                                    :actual_hours)

    result = {}
    result[:actual] = actual_result
    if is_full_month
      estimated_result = calculate_tasked_project_people(child_project_list,
                                                         project_name_id,
                                                         declared_people_hash,
                                                         percent_point,
                                                         :estimated_hours)
      result[:estimate] = estimated_result
    end
    result

  end

  def get_value_for_show_project_list(project_name_id_list, estimated_data, actual_data, is_full_month)
    value_hash = {}

    project_name_id_list.each_with_index do |project_name_id, index|
      project_name = project_name_id[0]
      project_id = project_name_id[1]
      total_estimate_value = get_total_value(estimated_data, index) if is_full_month
      total_actual_value = get_total_value(actual_data, index)

      data = []
      data.push(project_name)
      data.push(total_actual_value.inject(0, :+))
      data.push(total_estimate_value[0]) if is_full_month
      data.push(total_actual_value[0])
      data.push(total_estimate_value[1]) if is_full_month
      data.push(total_actual_value[1])
      data.push(total_estimate_value[2]) if is_full_month
      data.push(total_actual_value[2])
      data.push(total_estimate_value[3]) if is_full_month
      data.push(total_actual_value[3])

      value_hash[project_id] = data
    end

    value_hash
  end

  def get_report_task_percent(declared_people_hash, daysInMonth, type, cal_type)

    result = {}

    if cal_type == "estimate"
      sym = :estimated_hours
      result[:header] = "được giao việc"
    else
      sym = :actual_hours
      result[:header] = "thực tế làm việc"
    end

    if type.eql? "total"
      result[:declared_people_hash] = declared_people_hash
      return result
    end

    total_hours = daysInMonth.to_i * 8
    min_hours = nil
    max_hours = nil


    case type
    when "under_50"
      result[:header] += " dưới 50%"
      min_hours = nil
      max_hours = total_hours * 0.5
    when "under_70"
      result[:header] += " từ 50% đến 70%"
      min_hours = total_hours * 0.5
      max_hours = total_hours * 0.7
    when "under_100"
      result[:header] += " từ 70% đến 100%"
      min_hours = total_hours * 0.7
      max_hours = total_hours
    when "upper_100"
      result[:header] += " trên 100%"
      min_hours = total_hours
      max_hours = nil
    end

    declared_people_hash.delete_if {|k,v| !get_person_between_percent(min_hours, max_hours, v[sym])}
    result[:declared_people_hash] = declared_people_hash

    result
  end

  def link_to_department_task_total(hash_param,value)

    department_name = hash_param[:department_name]

    department = get_department_params(department_name, hash_param[:parent_department_id] )

    if department.nil?
      department_name
    else
      department_id = department.id.to_s
      link_to value, { :controller => 'task_reports',
                                 :action => 'by_department',
                                 :department_report => department_id,
                                 :month_report => hash_param[:month_report]}
    end
  end

  def link_to_department_task(hash_param)

    department_name = hash_param[:department_name]

    department = get_department_params(department_name, hash_param[:parent_department_id] )

    if department.nil?
      department_name
    else
      department_id = department.id.to_s
      link_to department_name, { :controller => 'task_reports',
                                 :action => 'by_department',
                                 :department_report => department_id,
                                 :month_report => hash_param[:month_report]}
    end
  end


  def link_to_child_project(project_id, project_name, time_reports)
    project = Project.find(project_id)

    return project_name unless project.present?

    link_to project.name, {:controller => 'task_reports',
                           :action => 'by_project',
                           :project_report => project.id,
                           :time_reports => time_reports}
  end


  def link_to_department_person_task_list(hash_param, value, type, cal_type)

    department = get_department_params(hash_param[:department_name], hash_param[:parent_department_id] )

    if department.nil?
      value
    else
      department_id = department.id.to_s
      link_to value, { :controller => 'task_reports',
                       :action => 'by_department',
                       :department_report => department_id,
                       :month_report => hash_param[:month_report],
                       :cal_type => cal_type,
                       :type => type }
    end
  end

  def link_to_selected_person_list(hash_param, value, type, cal_type)
    project_id = hash_param[:project_id]
    project = Project.find(project_id)

    return value if project.nil?

    link_to value, {:controller => 'task_reports',
                    :action => 'by_project',
                    :project_report => project_id,
                    :time_reports => hash_param[:time_reports],
                    :cal_type => cal_type,:type => type}
  end

  def get_tasked_person(person_id, value)
    person = Person.find(person_id)
    result = {}
    result[:login] = person
    result[:department_name] = person.department
    result[:estimated_hours] = value[:estimated_hours]
    result[:actual_hours] = value[:actual_hours]

    return result if result[:estimated_hours] == 0 && result[:actual_hours] == 0

    project_estimate_list = []
    value.each do |k,v|
      next if k.object_id == :estimated_hours.object_id ||k.object_id == :actual_hours.object_id
      project_estimate = {}
      project_estimate[:estimated_hours] = v[:estimate]
      project_estimate[:actual_hours] = v[:actual]
      project_estimate[:project] = Project.find(k)
      project_estimate_list.push(project_estimate)
    end
    result[:project_estimate_list] = project_estimate_list

    result
  end


  def get_information_for_a_person(person_id, value, is_full_month, total_hours, role_list)
    result = {}

    person = Person.find(person_id)

    estimated_hours = value[:estimated_hours] if is_full_month
    actual_hours = value[:actual_hours]

    value.delete(:estimated_hours) if is_full_month
    value.delete(:actual_hours)

    total_value = []
    total_value.push(person.login)
    total_value.push(estimated_hours) if is_full_month
    total_value.push(actual_hours)
    total_value.push(total_hours)
    total_value.push("#{((estimated_hours * 100)/total_hours).round(2)}%") if is_full_month
    total_value.push("#{((actual_hours * 100)/total_hours).round(2)}%")
    result[:total_value] = total_value

    is_declared_task = true
    is_declared_task = false if actual_hours == 0 and !is_full_month
    is_declared_task = false if actual_hours == 0 and estimated_hours == 0 and is_full_month

    if is_declared_task
      detail_project_count = 0
      detail_project = {}

      value.each do |project_id, child_value|
        next if child_value[:actual] == 0 && (child_value[:estimate].nil? || child_value[:estimate] == 0)
        project = Project.find(project_id)
        member = Member.where(:project_id => project_id, :user_id => person_id).first
        next if member.nil?

        roles = member.roles.map(&:name)
        roles.delete_if { |role| role_list.index(role).nil? }

        if child_value[:estimate].nil?
          child_project_estimate = 0
        else
          child_project_estimate = child_value[:estimate]
        end
        child_project_actual = child_value[:actual]

        detail_project_count += 1
        detail_value = []
        detail_value.push(project.name)
        detail_value.push(roles.join(', '))
        detail_value.push(child_project_estimate) if is_full_month
        detail_value.push(child_project_actual)
        detail_project[project_id] = detail_value
      end

      result[:detail_project_count] = detail_project_count
      result[:detail_project] = detail_project
    else
      result[:detail_project_count] = 0
    end
    result
  end

  def get_information_for_show_person_list(declared_people_hash, is_full_month, daysInMonth)
    role_list = get_roles
    total_hours = daysInMonth * 8

    person_list_data = {}
    declared_people_hash.each do |key, value|
      person_list_data[key] = get_information_for_a_person(key, value, is_full_month, total_hours, role_list)
    end
    person_list_data
  end

  def get_total_value(data, index)
    total_value = [0,0,0,0]
    (0..3).each do |i|
      total_value[i] = data[3-i][:data][index]
    end
    total_value
  end


  private

  def check_undeclared_person(person, begin_of_month, end_of_month)
    return true if person.appearance_date.present? and person.appearance_date > begin_of_month
    return true if person.leaving_date.present? and person.leaving_date < end_of_month
    false
  end

  def get_department_params(department_name, parent_department_id )
    if parent_department_id == 0
      parent_id = nil
    else
      parent_id = parent_department_id
    end
    Department.find_all_by_name(department_name, parent_id)
  end

  def get_person_between_percent(min_hours, max_hours, estimated_hours)
    if min_hours.nil?
      return true if estimated_hours < max_hours
      return false
    end

    if max_hours.nil?
      return true if estimated_hours >= min_hours
      return false
    end

    return true if estimated_hours >= min_hours && estimated_hours < max_hours
    false
  end

  def calculate_tasked_people(department_list, department_name_list, declared_people_hash, percent_point, type)
    total_department = department_name_list.count

    under_fifty_percent_hash = {}
    under_fifty_percent_hash[:name] = "< 50%"
    under_fifty_percent_hash[:data] = Array.new(total_department, 0)

    under_seventy_percent_hash = {}
    under_seventy_percent_hash[:name] = "50% - 70%"
    under_seventy_percent_hash[:data] = Array.new(total_department, 0)

    under_one_hundred_percent_hash = {}
    under_one_hundred_percent_hash[:name] = "70% - 100%"
    under_one_hundred_percent_hash[:data] = Array.new(total_department, 0)

    upper_one_hundred_percent_hash = {}
    upper_one_hundred_percent_hash[:name] = "> 100%"
    upper_one_hundred_percent_hash[:data] = Array.new(total_department, 0)

    department_list.each do |department|
      department_name = department.name
      next if department_name_list.index(department_name).nil?
      index = department_name_list.index(department_name)

      people_list = department.people_of_branch_department
      people_list.each do |person|
        person_id = person.id
        next unless declared_people_hash.key?(person_id)
        total_hours = declared_people_hash[person_id][type]
        if total_hours < percent_point[0]
          under_fifty_percent_hash[:data][index] += 1
        elsif total_hours < percent_point[1]
          under_seventy_percent_hash[:data][index] += 1
        elsif total_hours < percent_point[2]
          under_one_hundred_percent_hash[:data][index] += 1
        else
          upper_one_hundred_percent_hash[:data][index] += 1
        end
      end
    end
    [upper_one_hundred_percent_hash, under_one_hundred_percent_hash, under_seventy_percent_hash, under_fifty_percent_hash]
  end

  def calculate_tasked_project_people(project_list, project_name_id, declared_people_hash, percent_point, type)
    total_project = project_list.length

    under_fifty_percent_hash = {}
    under_fifty_percent_hash[:name] = "< 50%"
    under_fifty_percent_hash[:data] = Array.new(total_project, 0)

    under_seventy_percent_hash = {}
    under_seventy_percent_hash[:name] = "50% - 70%"
    under_seventy_percent_hash[:data] = Array.new(total_project, 0)

    under_one_hundred_percent_hash = {}
    under_one_hundred_percent_hash[:name] = "70% - 100%"
    under_one_hundred_percent_hash[:data] = Array.new(total_project, 0)

    upper_one_hundred_percent_hash = {}
    upper_one_hundred_percent_hash[:name] = "> 100%"
    upper_one_hundred_percent_hash[:data] = Array.new(total_project, 0)

    project_id_list = project_name_id.map {|name_id| name_id[1]}

    project_list.each do |key, value|
      value.each do |person_id|
        next unless declared_people_hash.key?(person_id)

        index = project_id_list.index(key)
        total_hours = declared_people_hash[person_id][type]
        if total_hours < percent_point[0]
          under_fifty_percent_hash[:data][index] += 1
        elsif total_hours < percent_point[1]
          under_seventy_percent_hash[:data][index] += 1
        elsif total_hours < percent_point[2]
          under_one_hundred_percent_hash[:data][index] += 1
        else
          upper_one_hundred_percent_hash[:data][index] += 1
        end
      end
    end
    [upper_one_hundred_percent_hash, under_one_hundred_percent_hash, under_seventy_percent_hash, under_fifty_percent_hash]
  end
end