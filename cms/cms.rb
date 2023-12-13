require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
end

helpers do
  # def format_text(string)
  #   string.gsub(/\n/, "<br>")
  # end
end

before do
end

root = File.expand_path("..", __FILE__)

get "/" do
  @files = Dir.glob(root + "/data/*").map{|path| File.basename(path)}
  erb :index
end

get "/:file" do
  path = root + "/data/" + params[:file]
  headers["Content-Type"] = "text/plain"
  File.read(path) if File.readable?(path)
end