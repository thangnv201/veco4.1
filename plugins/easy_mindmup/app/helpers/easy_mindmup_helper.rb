module EasyMindmupHelper

  # def avatar_url_from_avatar(avatar_html)
  #   start_index = avatar_html.index('src="')
  #   return '' if start_index.nil?
  #   start_index += 5
  #   end_index = avatar_html.index('"', start_index)
  #   avatar_html[start_index, end_index - start_index]
  # end

  def mindmup_avatar_url(user)
    if defined?(avatar_url)
      avatar_url(user)
    elsif Setting.gravatar_enabled?
      gravatar_url(user.mail.to_s.downcase, size: 64, default: Setting.gravatar_default)
    else
      ''
    end
  end

  def prepare_test_includes(tests)
    includes = []
    tests.each do |test_file|
      plugin = 'easy_mindmup'
      if test_file.include?('/')
        split = test_file.split('/')
        plugin = split[0]
        test_file = split[1]
      end
      includes << [test_file, plugin]
    end
    includes
  end

end
