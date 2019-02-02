# encoding: UTF-8

task :default => :new

require 'fileutils'

desc "创建新blog："
task :new do
    puts "请输入要创建的文件名："
    @url = STDIN.gets.chomp
    @name = "#{@url}"
    puts "请输入博客分类："
    @categories = STDIN.gets.chomp

    @slug = "#{@url}"
    @slug = @slug.strip.gsub(' ', '-')
    @date = Time.now.strftime("%F")
    @post_name = "_posts/#{@categories}/#{@date}-#{@slug}.md"
    if File.exist?(@post_name)
            abort("Error: 文件名已被使用 (ノ=Д=)ノ┻━┻ ")
    end
    FileUtils.touch(@post_name)
    open(@post_name, 'a:UTF-8') do |file|
            file.puts "---"
            file.puts "layout: post"
            file.puts "title: #{@name}"
            file.puts "author: itsxun"
            file.puts "date: #{Time.now}"
            file.puts "catalog: true"
            file.puts "tags:"
            file.puts "    - #{@categories}"
            file.puts "---"
    end
    puts "文件已生成，调用编辑器打开中，请稍后..."
    editor_path='"C:\Users\xun\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\GitHub, Inc\Atom"'
    exec "start #{editor_path} #{@post_name}"
end
