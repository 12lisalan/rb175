require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
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

  def sorted_lists(lists, &block)
    completed_list, incomplete_list = lists.partition{ |list| list_complete?(list) }

    incomplete_list.each{ |list| yield list, lists.index(list) }
    completed_list.each{ |list| yield list, lists.index(list) }
  end

  # sorts todos based on completion
  def sorted_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition{ |todo| todo[:completed] }

    incomplete_todos.each(&block)
    completed_todos.each(&block)
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

# lists = session[:lists] (array of list hashes)
# lists << {name: @list_name, todos: []} (one list)
# @list[:todos] << {id: id, name: todo_name, completed: false}
#   (one todo)
#   array of hashes

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
  @list_name = params[:list_name].strip

  error = error_for_list_name(@list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << {name: @list_name, todos: []}
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

def load_list(index)
  list = session[:lists][index] if (index && session[:lists][index])
  return list if list

  session[:error] = "The specified list was not found."
  redirect :lists
end

# view details about a single list
get "/lists/:id" do
  @id = params[:id].to_i
  @list = load_list(@id)
  erb :list
end

# render new edit name form
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = load_list(@id)
  @name = @list[:name]
  erb :edit
end

# edit list name
post "/lists/:id" do
  list_name = params[:list_name].strip
  @id = params[:id].to_i
  @list = load_list(@id)

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

# Delete a todo list
post "/lists/:id/delete" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

# return error message if name invalid.
# return nil if name is valid.
def error_for_todo_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  end
end

def next_todo_id(todos)
  max = todos.map{ |todo| todo[:id] }.max || 0
  max + 1
end

# add a new todo to the current list
post '/lists/:id/todos' do
  todo_name = params[:todo].strip
  id = params[:id].to_i
  @list = load_list(id)

  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error
    erb :list
  else

    todo_id = next_todo_id(@list[:todos])
    @list[:todos] << {id: todo_id, name: todo_name, completed: false}
    redirect "/lists/#{id}"
  end
end

# takes array of todos (list[:todo]) and index of todo `id`
# deletes todo with index `id` from `todos` array
def delete_todo(todos, id)
  todos.delete load_todo(todos, id)
end

# Delete a todo from a list
post "/lists/:id/todos/:todo_id/delete" do
  @id = params[:id].to_i
  @list = load_list(@id)

  todo_id = params[:todo_id].to_i
  #@list[:todos].delete_at todo_id
  #delete_todo(@list[:todos], todo_id)
  @list[:todos].reject! { |todo| todo[:id] == todo_id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@id}"
  end
end

# takes array of todos (list[:todo])
# returns todo (Hash) based on todo id (integer)
def load_todo(todos, id)
  todos.each do |todo|
    if todo[:id] == id
      return todo
    end
  end
end

# checks/unchecks specific todo item
# updates status of a todo
post "/lists/:id/todos/:todo_id" do
  id = params[:id].to_i
  list = load_list(id)
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"
  todo = load_todo(list[:todos], todo_id)
  todo[:completed] = is_completed
  session[:success] = %(The todo "#{todo[:name]}" is updated.)
  redirect "/lists/#{id}"
end

# marks all todos in one list to complete
post "/lists/:id/complete" do
  id = params[:id].to_i
  list = load_list(id)
  list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = %(The todo list is updated.)
  redirect "/lists/#{id}"
end