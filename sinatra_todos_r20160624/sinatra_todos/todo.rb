require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

set :session_secret, SecureRandom.hex(32)


helpers do
    # returns true if all items in passed in list is complete
  def list_complete?(list)
    total_count(list) > 0 && remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def remaining_count(list)
    list[:todos].count{ |todo| !todo[:completed] }
  end

  def total_count(list)
    list[:todos].size
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# GET /lists      -> view all lists
# GET /lists/new  -> new list form
# POST /lists     -> create new list
# GET /lists/1    -> view a single list
# POST

# view all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists
end

# render new list form
get "/lists/new" do
  erb :new_list
end

# return error message if name invalid.
# return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be unique."
  end
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

# view details about a single list
get "/lists/:id" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :list
end

# render new edit name form
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  @name = @list[:name]
  erb :edit
end

# edit list name
post "/lists/:id" do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = session[:lists][@id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit
  else
    @list[:name] = list_name
    session[:success] = "The list name has been updated."
    redirect "/lists/#{@id}"
  end
end

post "/lists/:id/delete" do
  list = session[:lists].delete_at(params[:id].to_i)
  session[:success] = %(The list "#{list[:name]}" has been deleted.)
  redirect "/lists"
end

# return error message if name invalid.
# return nil if name is valid.
def error_for_todo_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  end
end

# add a new todo to the current list
post '/lists/:id/todos' do
  todo_name = params[:todo].strip
  id = params[:id].to_i
  @list = session[:lists][id]

  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << {name: todo_name, completed: false}
    redirect "/lists/#{id}"
  end
end

# deletes todo at index
post "/lists/:id/todos/:todo_id/delete" do
  id = params[:id].to_i
  list = session[:lists][id]
  deleted_todo = list[:todos].delete_at(params[:todo_id].to_i)
  session[:success] = %(The todo "#{deleted_todo[:name]}" has been deleted.)
  redirect "/lists/#{id}"
end

# checks/unchecks specific todo item
# updates status of a todo
post "/lists/:id/todos/:todo_id" do
  id = params[:id].to_i
  list = session[:lists][id]
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"
  todo = list[:todos][todo_id]
  todo[:completed] = is_completed
  session[:success] = %(The todo "#{todo[:name]}" is updated.)
  redirect "/lists/#{id}"
end

# marks all todos in one list to complete
post "/lists/:id/complete" do
  id = params[:id].to_i
  list = session[:lists][id]
  list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = %(The todo list is updated.)
  redirect "/lists/#{id}"
end