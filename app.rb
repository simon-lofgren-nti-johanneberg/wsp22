require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require_relative 'model.rb'

enable :sessions

include Model

# Command which runs before anything else, making sure the user is using a correct route based on login status
#
before do 
  if session[:id] ==  nil && request.path_info != '/' && request.path_info != '/register' && request.path_info != '/login' && request.path_info != '/error'
    session[:error] = "Error: Not available route"
    redirect('/error')
  elsif session[:id] !=  nil && (request.path_info == '/' or request.path_info == '/register' or request.path_info == '/login')
    session[:error] = "Error: Not available route"
    redirect('/error') 
  end 
end 

# Display Landing Page
#
get('/') do
  session.destroy
  slim(:home)
end

# Displays an error message, removes all unrelevant sessions
#
get('/error') do 
  temp1 = session[:id]
  temp2 = session[:filter]
  temp3 = session[:error]
  session.destroy
  session[:id] = temp1 
  session[:filter] = temp2
  session[:error] = temp3
  session[:error]
end

# Displays a register form, removes all unrelevant sessions
#
get('/register') do
  temp1 = session[:error_register]
  session.destroy
  session[:error_register] = temp1
  slim(:register)
end

# Displays a login form, removes all unrelevant sessions
#
get('/login') do
  temp1 = session[:error_login]
  session.destroy
  session[:error_login] = temp1
  slim(:login)
end

# Displays a list of all users (only available for admin), removes all unrelevant sessions as well as a form button to ban or unban users
#
# @see Model#set_db
# @see Model#available_route
# @see Model#select_with_one_term
#
get('/users/') do
  set_db()
  temp1 = session[:id]
  session.destroy
  session[:id] = temp1 
  if available_route(session[:id])
    session[:error] = "Error: Not available route"
    redirect('/error') 
  end
  @users = select_with_one_term("*","users","role","user")
  slim(:"users/users")
end

#HÄR, har en hel del kvar, ska fixa post routes från users.slim men även kommentera routen ovan. Dessutom är available_route(user_id) inte kommenterad i model.rb. 

# Displays a form to confirm delete, removes all unrelevant sessions
#
# @param [Integer] :id, ID of selected exercise or workout to eventually delete
#
# @see Model#set_db
# @see Model#select_with_two_terms
# @see Model#correct_user
#
get('/exercises_workouts/:id/delete') do
  set_db()
  temp1 = session[:id]
  temp2 = session[:filter]
  session.destroy
  session[:id] = temp1 
  session[:filter] = temp2
  id = params[:id].to_i
  type = select_with_two_terms("type","exercises_workouts","id","user_id",id,session[:id]).first
  if correct_user(type)
    session[:error] = "Error: Unauthorized access"
    redirect('/error')
  end
  session[:type_delete] = type["type"]
  slim(:"exercises_workouts/delete")
end

# Displays an edit form, removes all unrelevant sessions
#
# @param [Integer] :id, ID of selected exercise or workout to edit
#
# @see Model#set_db
# @see Model#select_with_two_terms
# @see Model#correct_user
# @see Model#select_without_term
# @see Model#select_with_one_term
# @see Model#select_with_inner_join
#
get('/exercises_workouts/:id/edit') do
  set_db()
  temp1 = session[:id]
  temp2 = session[:filter]
  session.destroy
  session[:id] = temp1 
  session[:filter] = temp2
  id = params[:id].to_i
  type = select_with_two_terms("type","exercises_workouts","id","user_id",id,session[:id]).first
  if correct_user(type)
    session[:error] = "Error: Unauthorized access"
    redirect('/error')
  end
  session[:type_edit] = type["type"]
  @muscle_groups = select_without_term("label","muscle_groups")
  @exercises = select_with_two_terms("title","exercises_workouts","user_id","type",session[:id],"exercise")
  @title = select_with_one_term("title","exercises_workouts","id",id).first
  @included_muscle_groups = select_with_inner_join("label","relation_#{session[:type_edit]}_muscle","muscle_groups","muscle_group_id","id","#{session[:type_edit]}_id",id)
  if session[:type_edit] == "workout" 
    @included_exercises = select_with_inner_join("title","relation_exercise_workout","exercises_workouts","exercise_id","id","workout_id",id)
  end
  slim(:"exercises_workouts/edit")
end

# Displays a create form, based on selected type (exercise or workout) which is made in the connected slim-file (new.slim) if not already done, removes all unrelevant sessions
#
# @see Model#set_db
# @see Model#select_with_two_terms
# @see Model#select_without_term
#
get('/exercises_workouts/new') do
  set_db()
  temp1 = session[:id]
  temp2 = session[:error_new]
  temp3 = session[:type_new]
  session.destroy
  session[:id] = temp1 
  session[:error_new] = temp2
  session[:type_new] = temp3
  @exercises = select_with_two_terms("title","exercises_workouts","user_id","type",session[:id],"exercise")
  @muscle_groups = select_without_term("label","muscle_groups")
  slim(:"exercises_workouts/new")
end

# Displays details about a specific exercise or workout
#
# @param [Integer] :id, ID of selected exercise or workout to read
#
# @see Model#set_db
# @see Model#select_with_one_term
# @see Model#select_with_inner_join
#
get('/exercises_workouts/:id') do
  set_db()
  @id = params[:id].to_i
  @data = select_with_one_term("*","exercises_workouts","id",@id).first
  @included_muscle_groups = select_with_inner_join("label","relation_#{@data["type"]}_muscle","muscle_groups","muscle_group_id","id","#{@data["type"]}_id",@id)
  if @data["type"] == "workout"
    @included_exercises = select_with_inner_join("title","relation_exercise_workout","exercises_workouts","exercise_id","id","workout_id",@id)
  end
  slim(:"exercises_workouts/show")
end

# Displays exercises and/or workouts, based on selected filter from connected slim-file (index.slim), removes all unrelevant sessions
#
# @see Model#set_db
# @see Model#select_with_two_terms
#
get('/exercises_workouts/') do
  set_db()
  temp1 = session[:id]
  temp2 = session[:filter]
  temp3 = session[:error_edit]
  session.destroy
  session[:id] = temp1 
  session[:filter] = temp2
  session[:error_edit] = temp3
  @exercises = select_with_two_terms("*","exercises_workouts","user_id","type",session[:id],"exercise")
  @workouts = select_with_two_terms("*","exercises_workouts","user_id","type",session[:id],"workout")
  if session[:filter] == "exercise"
    @workouts = []
  elsif session[:filter] == "workout"
    @exercises = []
  end
  slim(:"exercises_workouts/index")
end

# Displays a form to confirm logout, removes all unrelevant sessions
#
get('/logout') do
  temp1 = session[:id]
  session.destroy
  session[:id] = temp1
  slim(:logout)
end

# Attemps to login, redirect to '/exercises_workouts/' and saving user_id as session
#
# @param [String] :username, User's written username from form
# @param [String] :password, User's written password from form
#
# @see Model#set_db
# @see Model#empty_fields
# @see Model#select_with_one_term
# @see Model#existing_user
# @see Model#correct_password
# @see Model#banned
#
post('/login') do
  set_db()
  username = params[:username].strip
  password = params[:password]
  if empty_fields(username,password)
    session[:error_login] = "Error: Your username and/or password can't be empty"
    redirect('/login') 
  end
  user = select_with_one_term("*","users","username",username).first
  if existing_user(user)
    session[:error_login] = "Error: Username does not exist"
    redirect('/login')
  end
  if correct_password(user["password_digest"],password)
    session[:error_login] = "Error: Wrong password"
    redirect('/login')
  end
  if banned(user["ban"])
    session[:error_login] = "Error: Account is banned"
    redirect('/login')
  end
  session[:id] = user["id"]
  redirect('/exercises_workouts/')
end

# Attemps to register and redirect to '/login'
#
# @param [String] :username, User's written username from form
# @param [String] :password, User's written password from form
# @param [String] :password_confirm, User's supposed to confirm recent password by writing it again
#
# @see Model#set_db
# @see Model#empty_fields
# @see Model#select_with_one_term
# @see Model#available_user
# @see Model#matching_passwords
# @see Model#crypt_password
# @see Model#insert_to_two_columns
#
post('/register') do
  set_db()
  username = params[:username].strip
  password = params[:password]
  password_confirm = params[:password_confirm]
  if empty_fields(username,password)
    session[:error_register] = "Error: Your username and/or password can't be empty"
    redirect('/register') 
  end
  eventual_data = select_with_one_term("*","users","username",username)
  if available_user(eventual_data)
    session[:error_register] = "Error: Username already taken"
    redirect('/register')
  end
  if matching_passwords(password,password_confirm)
    session[:error_register] = "Error: The passwords don't match"
    redirect('/register')
  end
  password_digest = crypt_password(password)
  insert_to_two_columns("users","username","password_digest",username,password_digest)
  redirect('/login')
end

# Logging out by deleting all sessions, included id of user and redirects to '/'
#
post('/logout') do
  session.destroy
  redirect('/')
end

# Filter types to be seen at the redirect route '/exercises_workouts/', removes eventual value of session[:error_edit]
#
# @param [String] :filter, Selected filter of type from form
#
post('/filter') do
  session[:error_edit] = nil
  filter = params[:filter]
    case filter
      when "all"
        session[:filter] = nil
      when "exercise"
        session[:filter] = "exercise"
      when "workout"
        session[:filter] = "workout"
    end
  redirect('/exercises_workouts/')
end

# Bans or unbans selected user, depending on current ban status and redirects to '/users/'
#
# @param [Integer] :id, ID of selected user to ban or unban
#
# @see Model#set_db
# @see Model#select_with_one_term
# @see Model#update_to_one_column
#
post('/users/:id/ban') do
  set_db()
  id = params[:id]
  ban = select_with_one_term("ban","users","id",id).first
  if ban["ban"] == 0 
    new_ban = 1
  else
    new_ban = 0
  end
  update_to_one_column("users","ban","id",new_ban,id)
  redirect('/users/')
end

# Deletes selected exercise or workout and all its data and redirects to '/exercises_workouts/'
#
# @param [Integer] :id, ID of selected exercise or workout to delete
#
# @see Model#set_db
# @see Model#delete
#
post('/exercises_workouts/:id/delete') do
  set_db()
  id = params[:id].to_i
  delete("exercises_workouts","id",id)
  delete("relation_#{session[:type_delete]}_muscle","#{session[:type_delete]}_id",id)
  delete("relation_exercise_workout","#{session[:type_delete]}_id",id) 
  redirect('/exercises_workouts/')
end 

# Attemps to update selected exercise or workout and redirects to '/exercises_workouts/'
#
# @param [Integer] :id, ID of selected exercise or workout to update
# @param [String] :title, Written title of exercise or workout from edit form, removed spaces back and front
# @param [String] :old_title, Recent used title of selected exercise or workout
#
# @see Model#set_db
# @see Model#empty_title
# @see Model#select_with_three_terms
# @see Model#existing_title
# @see Model#update_to_two_columns
# @see Model#delete
# @see Model#select_with_one_term
# @see Model#insert_to_two_columns
#
post('/exercises_workouts/:id/update') do
  set_db()
  id = params[:id].to_i
  title = params[:title].strip
  old_title = params[:old_title]
  chosen_muscle_groups = []
  chosen_exercises = []
  if empty_title(title)
    session[:error_edit] = "Error: Title can't be empty"
    redirect('/exercises_workouts/')
  end
  eventual_data = select_with_three_terms("*","exercises_workouts","title","user_id","type",title,session[:id],session[:type_edit])
  if existing_title(eventual_data,title,old_title)
    session[:error_edit] = "Error: Chosen title of #{session[:type_edit]} already exists"
    redirect('/exercises_workouts/')
  end
  session[:error_edit] = nil
  params.each do |element|
    if element[0][0, 1] == "m"
      muscle = element[0][1,element[0].length - 1]
      chosen_muscle_groups << muscle
    elsif element[0][0, 1] == "e"
      exercise = element[0][1,element[0].length - 1]
      chosen_exercises << exercise
    end
  end
  update_to_two_columns("exercises_workouts","title","user_id","id",title,session[:id],id)
  delete("relation_#{session[:type_edit]}_muscle","#{session[:type_edit]}_id",id)
  chosen_muscle_groups.each do |muscle|
    muscle_group_id = select_with_one_term("id","muscle_groups","label",muscle).first
    insert_to_two_columns("relation_#{session[:type_edit]}_muscle","#{session[:type_edit]}_id","muscle_group_id",id,muscle_group_id["id"])
  end
  if session[:type_edit] == "workout"
    delete("relation_exercise_workout","workout_id",id) 
    chosen_exercises.each do |exercise|
      exercise_id = select_with_three_terms("id","exercises_workouts","title","user_id","type",exercise,session[:id],"exercise").first
      insert_to_two_columns("relation_exercise_workout","exercise_id","workout_id",exercise_id["id"],id)
    end
  end
  redirect('/exercises_workouts/')
end

# Attemps to save user's selected type from new.slim in a session, a session used for create, redirects to '/exercises_workouts/new'
#
# @param [String] :type_new, Selected type from new.slim
#
post('/select_type') do 
  type = params[:type_new]
    case type
      when "select_type"
        session[:error_new] = "Error: You must select a type"
      when "exercise"
        session[:error_new] = nil
        session[:type_new] = type
      when "workout"
        session[:error_new] = nil
        session[:type_new] = type
    end
  redirect('/exercises_workouts/new')
end

# Attemps to create new exercise or workout, based on selected type from new.slim, redirects to '/exercises_workouts/'
#
# @param [String] :title, Written title of exercise or workout from new.slim, removed spaces back and front
#
# @see Model#set_db
# @see Model#empty_title
# @see Model#select_with_three_terms
# @see Model#existing_title
# @see Model#insert_to_three_columns
# @see Model#select_with_one_term
# @see Model#insert_to_two_columns
#
post('/exercises_workouts') do
  set_db()
  title = params[:title].strip
  old_title = nil
  chosen_muscle_groups = []
  chosen_exercises = []
  if empty_title(title)
    session[:error_new] = "Error: Title can't be empty"
    redirect('/exercises_workouts/new')
  end
  eventual_data = select_with_three_terms("*","exercises_workouts","title","user_id","type",title,session[:id],session[:type_new])
  if existing_title(eventual_data,title,old_title)
    session[:error_new] = "Error: Chosen title of #{session[:type_new]} already exists"
    redirect('/exercises_workouts/new')
  end
  params.each do |element|
    if element[0][0, 1] == "m"
      muscle = element[0][1,element[0].length - 1]
      chosen_muscle_groups << muscle
    elsif element[0][0, 1] == "e"
      exercise = element[0][1,element[0].length - 1]
      chosen_exercises << exercise
    end
  end
  id = insert_to_three_columns("exercises_workouts","title","user_id","type",title,session[:id],session[:type_new])
  chosen_muscle_groups.each do |muscle|
    muscle_group_id = select_with_one_term("id","muscle_groups","label",muscle).first
    insert_to_two_columns("relation_#{session[:type_new]}_muscle","#{session[:type_new]}_id","muscle_group_id",id,muscle_group_id["id"])
  end
  if session[:type_new] == "workout"
    chosen_exercises.each do |exercise|
      exercise_id = select_with_three_terms("id","exercises_workouts","title","user_id","type",exercise,session[:id],"exercise").first
      insert_to_two_columns("relation_exercise_workout","exercise_id","workout_id",exercise_id["id"],id)
    end
  end
  redirect('/exercises_workouts/')
end

